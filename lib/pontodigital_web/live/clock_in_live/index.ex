defmodule PontodigitalWeb.ClockInLive.Index do
  use PontodigitalWeb, :live_view

  alias Pontodigital.Timekeeping

  # 1. MOUNT: Busca os dados ao carregar a página
  @impl true
  def mount(_params, _session, socket) do
    # Identifica o usuário pelo escopo
    user = socket.assigns.current_scope.user

    # Busca a lista no banco de dados
    clock_ins = Timekeeping.list_clock_ins_by_user(user)

    # IMPORTANTE: Coloca a lista dentro do socket para o HTML usar
    {:ok, assign(socket, clock_ins: clock_ins, mode: :registrar)}
  end

  # 2. HANDLE EVENT: Salva o ponto quando clica no botão
  @impl true
  def handle_event("registrar_ponto", params, socket) do
    user = socket.assigns.current_scope.user

    # Pegamos o tipo do botão clicado (entry, lunch_out, etc)
    # Se não vier nada (ex: bug), assumimos "entry"
    type = Map.get(params, "type", "entry")

    case Timekeeping.create_clock_in(%{
           user_id: user.id,
           timestamp: DateTime.utc_now(),
           # Converte string "entry" para atom :entry
           type: String.to_existing_atom(type),
           origin: :web
         }) do
      {:ok, ponto} ->
        # Atualiza a lista na tela adicionando o novo ponto no topo
        socket = update(socket, :clock_ins, fn points -> [ponto | points] end)
        {:noreply, put_flash(socket, :info, "Ponto registrado: #{type}")}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Erro ao registrar ponto.")}
    end
  end

  @impl true
  def handle_event("trocar_modo", %{"modo" => novo_modo}, socket) do
    {:noreply, assign(socket, mode: String.to_existing_atom(novo_modo))}
  end
end
