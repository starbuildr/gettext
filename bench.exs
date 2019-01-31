po =
  File.read!("test/fixtures/po_editors/poedit.po")
  |> IO.inspect()

Benchee.run(%{
  "normal" => fn ->
    {:ok, _} = Gettext.PO.parse_string(po)
  end,
  "nimble" => fn ->
    {:ok, _} = Gettext.PO.parse_string_nimble(po)
  end
})
