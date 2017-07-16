defmodule Bridge.Web.API.UserTokenController do
  use Bridge.Web, :controller

  alias Bridge.Web.Auth

  plug :fetch_team
  plug :fetch_current_user_by_session

  def create(conn, _params) do
    user = conn.assigns.current_user

    if user do
      token = Auth.generate_signed_jwt(user)

      conn
      |> put_status(:created)
      |> render("create.json", %{token: token})
    else
      conn
      |> resp(:unauthorized, "")
    end
  end
end