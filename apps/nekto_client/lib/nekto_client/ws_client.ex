defmodule NektoClient.WSClient do
  def connect!(host) do
    Socket.Web.connect! host
  end

  def connect!(host, args) do
    Socket.Web.connect! host, args
  end

  def send!(socket, action, message \\ %{}) do
    Socket.Web.send!(socket,
      {
        :text,
        message
        |> Map.merge(%{action: action})
        |> Poison.encode!
      }
    )
  end

  def recv!(socket) do
    case Socket.Web.recv!(socket) do
      {:text, data} ->
        {:json, Poison.decode!(data)}
      data ->
        data
    end
  end

  def auth!(socket, user_token) do
    socket |> send!("AUTH", %{user_token: user_token})
  end

  def count_online_users!(socket) do
    socket |> send!("COUNT_ONLINE_USERS")
  end

  def search_company!(socket, params) do
    socket |> send!("SEARCH_COMPANY", params)
  end

  def typing_message!(socket, dialog_id, typing) do
    socket
    |> send!("TYPING_A_MESSAGE", %{dialog_id: dialog_id, typing: typing})
  end

  def chat_message!(socket, dialog_id, request_id, text) do
    socket
    |> send!("CHAT_MESSAGE", %{dialog_id: dialog_id, request_id: request_id, text: text})
  end

  def chat_message_read!(socket, dialog_id, message_ids) do
    socket
    |> send!("CHAT_MESSAGE_READ", %{dialog_id: dialog_id, message_ids: message_ids})
  end

  def leave_dialog!(socket, dialog_id) do
    socket |> send!("LEAVE_DIALOG", %{dialog_id: dialog_id})
  end

  def out_search_company!(socket) do
    socket |> send!("OUT_SEARCH_COMPANY")
  end
end
