defmodule Membrane.Kino.JSUtils do
  @moduledoc false

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
