defmodule Gettext.NimbleParserTest do
  use ExUnit.Case

  import Gettext.NimbleParser

  test "strings" do
    assert {:ok, ["foo"], "", _, _, _} = strings(~s("foo"))
    assert {:ok, ["føø"], "", _, _, _} = strings(~s("føø"))
    assert {:ok, ["føø bar"], "", _, _, _} = strings(~s("føø bar"))

    # Escaped chars.
    assert {:ok, ["foo \n bar"], "", _, _, _} = strings(~S("foo \n bar"))

    message = "did not expect newline inside string while processing at least one string"
    assert {:error, ^message, ~s(\noo"), _, _, _} = strings(~s("f\noo"))

    assert {:ok, ["foo", "bar"], "", _, _, _} = strings(~s("foo" "bar"))
    assert {:ok, ["foo", "bar"], "", _, _, _} = strings(~s("foo""bar"))
    assert {:ok, ["foo", "bar"], "", _, _, _} = strings(~s("foo"\n\n \n  "bar"))

    assert {:error, "expected at least one string", "", _, _, _} = strings(~s())
  end

  test "translation" do
    string = """
    # Hello
    msgctxt "context"
    msgid "foo"
    msgstr "bar"
    """

    assert {:ok, [translation], _, _, _, _} = translation(string)

    assert translation == %Gettext.PO.Translation{
             msgid: ["foo"],
             msgstr: ["bar"]
           }
  end

  test "plural translation" do
    string = """
    msgid "foo"
    msgid_plural "foos"
    msgstr[0] "bar" "bar"
    msgstr[1] "bars"
    """

    assert {:ok, [translation], _, _, _, _} = translation(string)

    assert translation == %Gettext.PO.PluralTranslation{
             msgid: ["foo"],
             msgid_plural: ["foos"],
             msgstr: %{0 => ["bar", "bar"], 1 => ["bars"]}
           }
  end
end
