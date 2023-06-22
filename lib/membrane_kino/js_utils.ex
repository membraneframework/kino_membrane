defmodule Membrane.Kino.JSUtils do
  @moduledoc false

  defmacro precompiled_asset(bundle_path) do
    resource_attrs =
      case verify_assets_checksums(bundle_path) do
        {:ok, external_resources} ->
          Enum.map(external_resources, &quote(do: @external_resource(unquote(&1))))

        {:error, diff} ->
          raise "Sources for asset \"#{bundle_path}\" differ: #{diff}"
      end

    quote do
      (unquote_splicing(resource_attrs))
      unquote(File.read!(bundle_path))
    end
  end

  defp verify_assets_checksums(bundle_path) do
    [pwd, paths | files_shas] =
      File.read!("#{bundle_path}.fingerprint")
      |> String.split("\n", trim: true)

    paths =
      paths
      |> String.split(" ")
      |> Enum.map(&Path.expand(&1, pwd))
      |> Enum.flat_map(&[&1 | Path.wildcard("#{&1}/**")])

    paths = [Path.expand(bundle_path) | paths]

    files_shas =
      Map.new(files_shas, fn file_sha ->
        [sha, file] = String.split(file_sha, ~r/\s+/, parts: 2)
        {Path.expand(file, pwd), sha}
      end)

    diff =
      paths
      |> Map.new(&{&1, nil})
      |> Map.merge(files_shas)
      |> Enum.reject(fn {path, digest} -> calc_digest(path) == digest end)

    if diff == [] do
      {:ok, paths}
    else
      {:error, Enum.map_join(diff, ", ", fn {path, _digest} -> path end)}
    end
  end

  defp calc_digest(path) do
    case File.read(path) do
      {:ok, data} -> :crypto.hash(:sha256, data) |> Base.encode16(case: :lower)
      {:error, :eisdir} -> nil
      {:error, reason} -> raise File.Error, reason: reason, action: "read file", path: path
    end
  end

  def serialize_label(label) do
    label = if String.valid?(label), do: label, else: inspect(label)
    label = String.replace(label, ~w(" @ \ / < >), "")

    if String.length(label) > 30 do
      String.slice(label, 0..22) <> "..." <> String.slice(label, -5..-1)
    else
      label
    end
  end

  def serialize_term(term) do
    term |> :erlang.term_to_binary() |> Base.encode64()
  end

  def parse_term(data) do
    data |> Base.decode64!() |> :erlang.binary_to_term()
  end
end
