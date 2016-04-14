Nonterminals grammar translations translation pluralizations pluralization
             strings comments.
Terminals str msgid msgid_plural msgstr plural_form comment.
Rootsymbol grammar.

grammar ->
  translations : '$1'.

% A series of translations. It can be just comments (which are discarded and can
% be empty anyways) or comments followed by a translation followed by other
% translations; in the latter case, comments are attached to the translation
% that follows them.
translations ->
  comments : [].
translations ->
  comments translation translations : [add_comments_to_translation('$2', '$1')|'$3'].

translation ->
  msgid strings comments msgstr strings : {translation, #{
    comments       => [],
    msgid          => '$2',
    msgstr         => '$5',
    po_source_line => extract_line('$1')
  }}.
translation ->
  msgid strings comments msgid_plural strings comments pluralizations : {plural_translation, #{
    comments       => [],
    msgid          => '$2',
    msgid_plural   => '$5',
    msgstr         => plural_forms_map_from_list('$7'),
    po_source_line => extract_line('$1')
  }}.
% A bunch of malformed translations.
%% translation ->
%%   msgid strings :
%%     {malformed_translation, extract_line('$1'), <<"missing msgstr">>}.
%% translation ->
%%   msgid strings msgid_plural strings :
%%     {malformed_translation, extract_line('$3'), <<"missing msgstr">>}.

pluralizations ->
  pluralization : ['$1'].
pluralizations ->
  pluralization pluralizations : ['$1'|'$2'].

pluralization ->
  msgstr plural_form strings : {'$2', '$3'}.

strings ->
  str : [extract_simple_token('$1')].
strings ->
  str strings : [extract_simple_token('$1')|'$2'].

comments ->
  '$empty' : [].
comments ->
  comment comments : [extract_simple_token('$1')|'$2'].


Erlang code.

extract_simple_token({_Token, _Line, Value}) ->
  Value.

extract_line({_Token, Line}) ->
  Line.

plural_forms_map_from_list(Pluralizations) ->
  Tuples = lists:map(fun extract_plural_form/1, Pluralizations),
  maps:from_list(Tuples).

extract_plural_form({{plural_form, _Line, PluralForm}, String}) ->
  {PluralForm, String}.

add_comments_to_translation({Type, Translation}, Comments)
  when Type == translation; Type == plural_translation ->
  {Type, maps:put(comments, Comments, Translation)};
add_comments_to_translation({malformed_translation, _, _} = Translation, _Comments) ->
  Translation.
