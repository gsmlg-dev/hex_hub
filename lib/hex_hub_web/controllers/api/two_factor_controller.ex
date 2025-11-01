defmodule HexHubWeb.API.TwoFactorController do
  use HexHubWeb, :controller

  alias HexHub.Audit
  alias HexHub.TwoFactorAuth

  @doc """
  GET /api/auth/totp
  Get TOTP setup information for the current user.
  """
  def setup(conn, _params) do
    username = conn.assigns.current_user.username

    {:ok, setup_data} = TwoFactorAuth.generate_secret(username)

    json(conn, %{
      secret: setup_data.secret,
      uri: setup_data.uri,
      qr_code: setup_data.qr_code
    })
  end

  @doc """
  POST /api/auth/totp
  Enable TOTP for the current user.
  """
  def enable(conn, %{"secret" => secret, "code" => code}) do
    username = conn.assigns.current_user.username

    case TwoFactorAuth.enable_2fa(username, secret, code) do
      {:ok, %{recovery_codes: codes}} ->
        # Log the 2FA enablement
        Audit.log_event(
          "2fa.enabled",
          "user",
          username,
          %{
            ip_address: get_ip(conn)
          },
          conn
        )

        json(conn, %{
          message: "Two-factor authentication enabled successfully",
          recovery_codes: codes
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def enable(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameters: secret and code"})
  end

  @doc """
  DELETE /api/auth/totp
  Disable TOTP for the current user.
  """
  def disable(conn, %{"code" => code}) do
    username = conn.assigns.current_user.username

    case TwoFactorAuth.disable_2fa(username, code) do
      :ok ->
        # Log the 2FA disablement
        Audit.log_event(
          "2fa.disabled",
          "user",
          username,
          %{
            ip_address: get_ip(conn)
          },
          conn
        )

        json(conn, %{message: "Two-factor authentication disabled successfully"})

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def disable(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameter: code"})
  end

  @doc """
  POST /api/auth/totp/verify
  Verify a TOTP code.
  """
  def verify(conn, %{"code" => code}) do
    username = conn.assigns.current_user.username

    case TwoFactorAuth.verify_user_code(username, code) do
      :ok ->
        # Store 2FA verification in session/token
        conn
        |> put_session(:totp_verified, true)
        |> put_session(:totp_verified_at, DateTime.utc_now())
        |> json(%{message: "Code verified successfully"})

      {:error, :not_enabled} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Two-factor authentication is not enabled"})

      {:error, :invalid_code} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: "Invalid code"})

      {:error, reason} ->
        conn
        |> put_status(:internal_server_error)
        |> json(%{error: reason})
    end
  end

  def verify(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameter: code"})
  end

  @doc """
  POST /api/auth/totp/recovery
  Verify a recovery code.
  """
  def verify_recovery(conn, %{"code" => code}) do
    username = conn.assigns.current_user.username

    case TwoFactorAuth.verify_recovery_code(username, code) do
      :ok ->
        # Log recovery code usage
        Audit.log_event(
          "2fa.recovery_code_used",
          "user",
          username,
          %{
            ip_address: get_ip(conn)
          },
          conn
        )

        conn
        |> put_session(:totp_verified, true)
        |> put_session(:totp_verified_at, DateTime.utc_now())
        |> json(%{message: "Recovery code verified successfully"})

      {:error, reason} ->
        conn
        |> put_status(:unauthorized)
        |> json(%{error: reason})
    end
  end

  def verify_recovery(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameter: code"})
  end

  @doc """
  POST /api/auth/totp/recovery/regenerate
  Generate new recovery codes.
  """
  def regenerate_recovery_codes(conn, %{"code" => code}) do
    username = conn.assigns.current_user.username

    case TwoFactorAuth.regenerate_recovery_codes(username, code) do
      {:ok, codes} ->
        # Log recovery code regeneration
        Audit.log_event(
          "2fa.recovery_codes_regenerated",
          "user",
          username,
          %{
            ip_address: get_ip(conn)
          },
          conn
        )

        json(conn, %{
          message: "Recovery codes regenerated successfully",
          recovery_codes: codes
        })

      {:error, reason} ->
        conn
        |> put_status(:bad_request)
        |> json(%{error: reason})
    end
  end

  def regenerate_recovery_codes(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Missing required parameter: code"})
  end

  # Helper function to get IP address
  defp get_ip(conn) do
    conn.remote_ip
    |> Tuple.to_list()
    |> Enum.join(".")
  end
end
