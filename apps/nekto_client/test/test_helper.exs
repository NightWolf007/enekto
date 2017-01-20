Code.require_file "test/support/ws_server_mock.exs"
Code.require_file "test/support/handler.exs"
ExUnit.start()
Application.ensure_all_started(:bypass)
