defmodule Gettext.NimbleParser.Helpers do
  import NimbleParsec

  def newline() do
    ascii_char([?\n])
    |> label("newline")
    |> ignore()
  end

  def strings() do
    optional_whitespace =
      ascii_char([?\s, ?\n, ?\r, ?\t])
      |> times(min: 0)
      |> label("whitespace")
      |> ignore()

    double_quote =
      ascii_char([?"])
      |> label("double quote")
      |> ignore()

    escaped_char =
      choice([
        string(~S(\n)) |> replace(?\n),
        string(~S(\t)) |> replace(?\t),
        string(~S(\r)) |> replace(?\r),
        string(~S(\")) |> replace(?\"),
        string(~S(\\)) |> replace(?\\)
      ])

    string =
      double_quote
      |> repeat(choice([escaped_char, utf8_char(not: ?", not: ?\n)]))
      |> label(lookahead_not(newline()), "newline inside string")
      |> concat(double_quote)
      |> reduce(:to_string)

    string
    |> concat(optional_whitespace)
    |> times(min: 1)
    |> label("at least one string")
  end

  def whitespace_no_nl() do
    ascii_char([?\s, ?\r, ?\t])
    |> times(min: 1)
    |> label("whitespace")
    |> ignore()
  end

  def keyword(keyword) when is_atom(keyword) do
    string(Atom.to_string(keyword))
    |> ignore()
    |> concat(whitespace_no_nl())
    |> concat(strings())
    |> tag(keyword)
    |> label("#{keyword} followed by strings")
  end

  def comment() do
    optional(whitespace_no_nl())
    |> string("#")
    |> repeat(utf8_char(not: ?\n))
    |> concat(newline())
    |> reduce(:to_string)
    |> tag(:comment)
    |> label("comment")
  end

  def plural_form() do
    plural_form =
      ignore(string("["))
      |> integer(min: 1)
      |> ignore(string("]"))
      |> label("plural form (like [0])")

    msgstr_with_plural_form =
      ignore(string("msgstr"))
      |> concat(plural_form)

    msgstr_with_plural_form
    |> concat(whitespace_no_nl())
    |> concat(strings())
    |> reduce({__MODULE__, :make_plural_form, []})
    |> unwrap_and_tag(:plural_form)
  end

  def make_plural_form([plural_form | strings]) do
    {plural_form, strings}
  end
end

defmodule Gettext.NimbleParser do
  import NimbleParsec
  import Gettext.NimbleParser.Helpers

  singular_translation =
    repeat(comment())
    |> ignore(optional(keyword(:msgctxt)))
    |> concat(keyword(:msgid))
    |> concat(keyword(:msgstr))
    |> reduce(:make_singular_translation)
    |> label("translation")

  plural_translation =
    repeat(comment())
    |> ignore(optional(keyword(:msgctxt)))
    |> concat(keyword(:msgid))
    |> concat(keyword(:msgid_plural))
    |> times(plural_form(), min: 1)
    |> reduce(:make_plural_translation)
    |> label("plural translation")

  translation = choice([singular_translation, plural_translation])

  defparsec(:strings, strings())
  defparsec(:translation, translation)
  defparsec(:po_file, times(translation, min: 1), inline: true)

  defp make_singular_translation(tokens) do
    %Gettext.PO.Translation{
      msgid: Keyword.fetch!(tokens, :msgid),
      msgstr: Keyword.fetch!(tokens, :msgstr)
    }
  end

  defp make_plural_translation(tokens) do
    %Gettext.PO.PluralTranslation{
      msgid: Keyword.fetch!(tokens, :msgid),
      msgid_plural: Keyword.fetch!(tokens, :msgid_plural),
      msgstr: tokens |> Keyword.get_values(:plural_form) |> Map.new()
    }
  end
end
