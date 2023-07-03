defmodule KinoMembrane.ComponentInfo do
  @moduledoc """
  Kino that displays information about a Membrane component.

  It shows the component path, pads, charts with metrics and more -
  better check it yourself by clicking an element on the `KinoMembrane.PipelineGraph`
  or `KinoMembrane.PipelineTree`.

  Currently it supports elements only.
  """
  use GenServer

  require Membrane.Pad, as: Pad

  alias KinoMembrane.JSUtils
  alias VegaLite, as: Vl

  @nothing Kino.Markdown.new("")

  @enforce_keys [:pid, :frame]
  defstruct @enforce_keys

  defimpl Kino.Render do
    @impl true
    def to_livebook(%{frame: frame}), do: Kino.Render.to_livebook(frame)
  end

  @type t :: Kino.Render.t()

  @spec new(pipeline :: pid()) :: t
  def new(pipeline) do
    frame = empty_frame()
    {:ok, pid} = GenServer.start_link(__MODULE__, {frame, pipeline})
    %__MODULE__{pid: pid, frame: frame}
  end

  @spec set_component(t, Membrane.ComponentPath.path()) :: :ok
  def set_component(%__MODULE__{pid: pid}, component_path) do
    send(pid, {:set_component, component_path})
    :ok
  end

  @impl true
  def init({frame, pipeline}) do
    observer = Membrane.Core.Pipeline.get_observer(pipeline)

    component_frame = empty_frame()
    charts_container = empty_frame()

    Kino.Frame.render(frame, Kino.Layout.grid([component_frame, charts_container]))

    {:ok,
     %{
       component_alive?: true,
       links: MapSet.new(),
       component_frame: component_frame,
       chosen_component: nil,
       charts_container: charts_container,
       charts: %{},
       charts_frames: %{},
       observer: observer
     }}
  end

  @impl true
  def handle_info({:metrics, metrics, timestamp}, state) do
    metrics
    |> Enum.reduce(state, fn {{_metric, _path, pad} = key, value}, state ->
      charts_frames =
        Map.put_new_lazy(state.charts_frames, pad, fn ->
          frame = empty_frame()
          Kino.Frame.append(state.charts_container, frame)
          frame
        end)

      charts =
        if Map.has_key?(state.charts, key) do
          state.charts
        else
          chart = create_chart(key)
          charts = Map.put(state.charts, key, chart)
          render_charts(charts, pad, charts_frames[pad])
          charts
        end

      Kino.VegaLite.push(charts[key], %{x: timestamp, y: value}, window: 30)

      %{state | charts: charts, charts_frames: charts_frames}
    end)
    |> then(&{:noreply, &1})
  end

  @impl true
  def handle_info({:graph, action, graph}, state) do
    {component, links} = Enum.split_with(graph, &(&1.entity == :component))

    state = %{state | component_alive?: action == :add or Enum.empty?(component)}

    links =
      case action do
        :add -> MapSet.union(state.links, MapSet.new(links))
        :remove -> MapSet.difference(state.links, MapSet.new(links))
      end

    state = %{state | links: links}
    render_component(state)
    {:noreply, state}
  end

  @impl true
  def handle_info({{:set_component_button, path}, _origin}, state) do
    handle_info({:set_component, path}, state)
  end

  @impl true
  def handle_info({:set_component, path}, state) do
    if path != state.chosen_component do
      Membrane.Core.Observer.subscribe(
        state.observer,
        [metrics: [path: path], graph: [path: path]],
        confirm: path
      )
    end

    {:noreply, state}
  end

  def handle_info({:subscribed, path}, state) do
    no_pad_frame = empty_frame()

    state = %{
      state
      | chosen_component: path,
        links: MapSet.new(),
        charts_frames: %{nil => no_pad_frame},
        charts: %{}
    }

    render_component(state)
    Kino.Frame.render(state.charts_container, no_pad_frame)

    {:noreply, state}
  end

  defp render_component(state) do
    %{chosen_component: path, component_frame: container, links: links} = state
    name = List.last(path)

    pads =
      links
      |> Enum.map(fn %{from: from, to: to, input: input, output: output} ->
        case path do
          ^from -> %{direction: :output, pad: output, other_component: to, other_pad: input}
          ^to -> %{direction: :input, pad: input, other_component: from, other_pad: output}
        end
      end)
      |> Enum.sort()
      |> Enum.sort_by(& &1.direction, :desc)
      |> Enum.flat_map(fn %{pad: pad, other_component: other_component, other_pad: other_pad} ->
        button = Kino.Control.button("Go to linked component")
        Kino.Control.subscribe(button, {:set_component_button, other_component})

        [
          Kino.Markdown.new("""
          * Pad #{pretty_pad_name(pad)}

            linked to #{pretty_component_name(List.last(other_component))}
            #{pretty_path(other_component)}

            via #{pretty_pad_name(other_pad)}
          """),
          button
        ]
      end)

    layout =
      Kino.Layout.grid(
        [
          @nothing,
          Kino.Markdown.new("""
          ### Component #{pretty_component_name(name)}
          Name:
          ```elixir
          #{name}
          ```
          #{if length(path) > 2, do: "Path:\n#{pretty_path(path)}", else: ""}

          Status: **#{if state.component_alive?, do: "alive", else: "dead"}**
          """),
          if(pads == [], do: @nothing, else: Kino.Markdown.new("### Pads"))
        ] ++ pads ++ [Kino.Markdown.new("### Metrics")]
      )

    Kino.Frame.render(container, layout)
  end

  defp create_chart({metric, _path, _metric_id}) do
    Vl.new(width: 350, height: 300, title: "#{metric}")
    |> Vl.mark(:line, point: true)
    # |> Vl.param("grid", select: :interval, bind: :scales)
    |> Vl.encode_field(:x, "x", title: "Time [s]", type: :temporal)
    |> Vl.encode_field(:y, "y",
      title: "",
      type: :quantitative,
      scale: %{zero: false},
      axis: %{format: "s"}
    )
    # |> Vl.data_from_values(values)
    |> Kino.VegaLite.new()
  end

  defp render_charts(charts, pad, frame) do
    charts =
      charts
      |> Enum.filter(fn {{_metric, _path, chart_pad}, _chart} -> chart_pad == pad end)
      |> Enum.sort_by(fn {{metric, _path, _pad}, _chart} -> "#{metric}" end)
      |> Enum.map(fn {_key, chart} -> chart end)

    Kino.Layout.grid([
      Kino.Markdown.new(if pad, do: "#### Pad #{pretty_pad_name(pad)}", else: ""),
      Kino.Layout.grid(charts, columns: 2)
    ])
    |> then(&Kino.Frame.render(frame, &1))
  end

  defp empty_frame() do
    frame = Kino.Frame.new()
    Kino.Frame.render(frame, @nothing)
    frame
  end

  defp pretty_path(path) do
    path =
      path
      |> tl()
      |> Enum.with_index(2)
      |> Enum.map_join("\n", fn {name, i} -> "#{String.duplicate("  ", i)}#{name}" end)

    """
      ```elixir
    #{path}
      ```
    """
  end

  defp pretty_pad_name(Pad.ref(name, id)) do
    """
    #{pretty_atom(name)}
      ```elixir
      id: #{inspect(id)}
      ```
    """
  end

  defp pretty_pad_name(name) do
    pretty_atom(name)
  end

  defp pretty_component_name(name) do
    "<span style='color:#62b3ef'>#{JSUtils.serialize_label(name)}</span>"
  end

  defp pretty_atom(name) do
    "<span style='color:#62b3ef'>#{inspect(name)}</span>"
  end
end
