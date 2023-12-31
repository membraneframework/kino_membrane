defmodule KinoMembrane.JSUtils do
  @moduledoc false

  @doc """
  Registers a precompiled asset/bundle in a module.

  Accepts the path to the project that generated the asset
  and to the asset within the project. Returns the path to
  the asset relative to Mix project root.

  This macro makes sure that:
    - the module is recompiled when the asset changes
    - the project that generated the asset didn't change
      since the asset was generated (compilation will fail
      in such a case)

  To achieve that, the macro requires to generate a fingerprint
  of the project each time the asset is generated, by calling
  the following (or equivalent) script:

  ```sh
  #!/usr/bin/env bash
  (echo $@ && find $@ -type f -print0 | xargs -0 sha256sum) > .fingerprint
  ```

  and passing to it:
    - a wildcard for the generated assets as the first argument
    - wildcards for all files that contribute to generation of the assets

  for example:

  ```sh
  calc_fingerprint.sh precompiled/*.js src package.json package-lock.json
  ```
  """
  defmacro precompiled_asset(project_root, bundle_wildcard) do
    bundle_wildcard = path_expand_relative(bundle_wildcard, project_root)

    resource_attrs =
      case verify_assets_checksums(project_root, bundle_wildcard) do
        {:ok, external_resources} ->
          Enum.map(external_resources, &quote(do: @external_resource(unquote(&1))))

        {:error, diff} ->
          raise """
          Asset \"#{bundle_wildcard}\" is outdated and must be recompiled, because it relies on files that have changed:
          \t#{Enum.join(diff, ", ")}
          """
      end

    quote do
      (unquote_splicing(resource_attrs))
      :ok
    end
  end

  defp verify_assets_checksums(project_root, bundle_wildcard) do
    [paths | files_shas] =
      File.read!("#{project_root}/.fingerprint")
      |> String.split("\n", trim: true)

    paths =
      paths
      |> String.split(" ")
      |> Enum.map(&path_expand_relative(&1, project_root))
      # to make sure that the bundle is considered in the fingerprint
      |> then(&[bundle_wildcard | &1])
      |> Enum.flat_map(&[&1 | Path.wildcard("#{&1}/**")])

    files_shas =
      Map.new(files_shas, fn file_sha ->
        [sha, file] = String.split(file_sha, ~r/\s+/, parts: 2)
        {path_expand_relative(file, project_root), sha}
      end)

    diff =
      paths
      |> Map.new(&{&1, nil})
      |> Map.merge(files_shas)
      |> Enum.reject(fn {path, digest} -> calc_digest(path) == digest end)

    if diff == [] do
      {:ok, paths}
    else
      {:error, Enum.map(diff, fn {path, _digest} -> path end)}
    end
  end

  defp calc_digest(path) do
    case File.read(path) do
      {:ok, data} -> :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
      {:error, :eisdir} -> nil
      {:error, :enoent} -> nil
      {:error, reason} -> raise File.Error, reason: reason, action: "read file", path: path
    end
  end

  defp path_expand_relative(path, relative_to) do
    path |> Path.expand(relative_to) |> Path.relative_to_cwd()
  end

  @spec serialize_label(term) :: String.t()
  def serialize_label(label) do
    label = if is_binary(label) and String.valid?(label), do: label, else: inspect(label)
    label = String.replace(label, ~w(" @ \ / < >), "")

    if String.length(label) > 30 do
      String.slice(label, 0..22) <> "..." <> String.slice(label, -5..-1)
    else
      label
    end
  end

  @spec serialize_term(term) :: String.t()
  def serialize_term(term) do
    term |> :erlang.term_to_binary() |> Base.encode64()
  end

  @spec parse_term(String.t()) :: term
  def parse_term(data) do
    data |> Base.decode64!() |> :erlang.binary_to_term()
  end
end
