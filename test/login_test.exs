defmodule LoginTest do
  use PhoenixTokenAuth.Case
  use Plug.Test
  import RouterHelper
  alias PhoenixTokenAuth.TestRouter
  alias PhoenixTokenAuth.Registrator
  alias PhoenixTokenAuth.Confirmator
  import PhoenixTokenAuth.Util


  @email "user@example.com"
  @password "secret"
  @headers [{"Content-Type", "application/json"}]

  test "sign in with unknown email" do
    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, email: @email}, @headers)
    assert conn.status == 401
    assert conn.resp_body == Poison.encode!(%{errors: ["unknown_email_or_password"]})
  end

  test "sign in with wrong password" do
    Registrator.changeset(%{email: @email, password: @password})
    |> repo.insert

    conn = call(TestRouter, :post, "/api/sessions", %{password: "wrong", email: @email}, @headers)
    assert conn.status == 401
    assert conn.resp_body == Poison.encode!(%{errors: ["unknown_email_or_password"]})
  end

  test "sign in as unconfirmed user" do
    {_, changeset} = Registrator.changeset(%{email: @email, password: @password})
    |> Confirmator.sign_up_changeset
    repo.insert changeset

    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, email: @email}, @headers)
    assert conn.status == 401
    assert conn.resp_body == Poison.encode!(%{errors: ["account_not_confirmed"]})
  end

  test "sign in as confirmed user" do
    Registrator.changeset(%{email: @email, password: @password})
    |> Ecto.Changeset.put_change(:confirmed_at, Ecto.DateTime.utc)
    |> repo.insert

    conn = call(TestRouter, :post, "/api/sessions", %{password: @password, email: @email}, @headers)
    assert conn.status == 200
    assert match?(%{"token" => _}, Poison.decode!(conn.resp_body))
  end

end
