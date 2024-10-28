(* ::Section::Closed:: *)
(*Package Header*)
BeginPackage[ "Wolfram`Chatbook`Utils`" ];
Begin[ "`Private`" ];

Needs[ "Wolfram`Chatbook`"        ];
Needs[ "Wolfram`Chatbook`Common`" ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Config*)
$tinyHashLength = 5;

$messageToStringDelimiter = "\n\n";
$messageToStringTemplate  = StringTemplate[ "`Role`: `Content`" ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*AssociationKeyDeflatten*)
(* https://resources.wolframcloud.com/FunctionRepository/resources/AssociationKeyDeflatten *)
importResourceFunction[ associationKeyDeflatten, "AssociationKeyDeflatten" ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*ClickToCopy*)
(* https://resources.wolframcloud.com/FunctionRepository/resources/ClickToCopy *)
importResourceFunction[ clickToCopy, "ClickToCopy" ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*RelativeTimeString*)
(* https://resources.wolframcloud.com/FunctionRepository/resources/RelativeTimeString *)
importResourceFunction[ relativeTimeString, "RelativeTimeString" ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*SelectByCurrentValue*)
(* https://resources.wolframcloud.com/FunctionRepository/resources/SelectByCurrentValue *)
importResourceFunction[ selectByCurrentValue, "SelectByCurrentValue" ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Strings*)

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*messagesToString*)
messagesToString // beginDefinition;

messagesToString // Options = {
    "IncludeSystemMessage"     -> False,
    "IncludeTemporaryMessages" -> False,
    "MessageDelimiter"         -> $messageToStringDelimiter,
    "MessageTemplate"          -> $messageToStringTemplate
};

messagesToString[ { }, opts: OptionsPattern[ ] ] :=
    "";

messagesToString[ messages0_, opts: OptionsPattern[ ] ] := Enclose[
    Catch @ Module[ { messages, system, temporary, template, delimiter, reverted, strings },

        messages = ConfirmMatch[ messages0, $$chatMessages, "Messages" ];

        (* Check if the system messages should be included: *)
        system = ConfirmMatch[ OptionValue[ "IncludeSystemMessage" ], True|False, "System" ];
        If[ ! system, messages = Replace[ messages, { KeyValuePattern[ "Role" -> "System" ], m___ } :> { m } ] ];
        If[ messages === { }, Throw[ "" ] ];

        (* Check if the temporary messages should be included: *)
        temporary = ConfirmMatch[ OptionValue[ "IncludeTemporaryMessages" ], True|False, "Temporary" ];
        If[ ! temporary, messages = DeleteCases[ messages, KeyValuePattern[ "Temporary" -> True ] ] ];
        If[ messages === { }, Throw[ "" ] ];

        template = ConfirmMatch[ OptionValue[ "MessageTemplate" ], _String|_TemplateObject|None, "Template" ];
        delimiter = ConfirmMatch[ OptionValue[ "MessageDelimiter" ], _String, "Delimiter" ];

        reverted = ConfirmMatch[
            revertMultimodalContent @ messages,
            { KeyValuePattern[ "Content" -> _String ].. },
            "Reverted"
        ];

        strings = ConfirmMatch[
            If[ template === None, Lookup[ reverted, "Content" ], TemplateApply[ template, # ] & /@ reverted ],
            { __String },
            "Strings"
        ];

        ConfirmBy[ StringRiffle[ strings, delimiter ], StringQ, "Result" ]
    ],
    throwInternalFailure
];

messagesToString[ { messages__ }, assistant_String, opts: OptionsPattern[ ] ] :=
    messagesToString[ { messages, <| "Role" -> "Assistant", "Content" -> assistant |> }, opts ];

messagesToString // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*fixLineEndings*)
fixLineEndings // beginDefinition;
fixLineEndings[ string_String? StringQ ] := StringReplace[ string, "\r\n" -> "\n" ];
fixLineEndings // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*convertUTF8*)
convertUTF8 // beginDefinition;
convertUTF8[ string_String ] := convertUTF8[ string, True ];
convertUTF8[ string_String, True  ] := FromCharacterCode[ ToCharacterCode @ string, "UTF-8" ];
convertUTF8[ string_String, False ] := FromCharacterCode @ ToCharacterCode[ string, "UTF-8" ];
convertUTF8 // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*stringTrimMiddle*)
stringTrimMiddle // beginDefinition;
stringTrimMiddle[ str_String, Infinity ] := str;
stringTrimMiddle[ str_String, 0 ] := "";
stringTrimMiddle[ str_String, max_Integer? Positive ] := stringTrimMiddle[ str, Ceiling[ max / 2 ], Floor[ max / 2 ] ];
stringTrimMiddle[ str_String, l_Integer, r_Integer ] /; StringLength @ str <= l + r + 5 := str;
stringTrimMiddle[ str_String, l_Integer, r_Integer ] := StringTake[ str, l ] <> " ... " <> StringTake[ str, -r ];
stringTrimMiddle // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*makeFailureString*)
makeFailureString // beginDefinition;

makeFailureString[ failure: Failure[ tag_, as_Association ] ] := Enclose[
    Module[ { message },
        message = ToString @ ConfirmBy[ failure[ "Message" ], StringQ, "Message" ];
        StringJoin[
            "Failure[",
                ToString[ tag, InputForm ],
                ", ",
                StringReplace[
                    ToString[ as, InputForm ],
                    StartOfString~~"<|" -> "<|" <> ToString[ "Message" -> message, InputForm ] <> ", "
                ],
            "]"
        ]
    ],
    throwInternalFailure[ makeFailureString @ failure, ##1 ] &
];

makeFailureString // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*containsWordsQ*)
containsWordsQ // beginDefinition;
containsWordsQ[ p_ ] := containsWordsQ[ #, p ] &;
containsWordsQ[ m_String, p_List ] := containsWordsQ[ m, StringExpression @@ Riffle[ p, Except[ WordCharacter ]... ] ];
containsWordsQ[ m_String, p_ ] := StringContainsQ[ m, WordBoundary~~p~~WordBoundary, IgnoreCase -> True ];
containsWordsQ // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Files*)

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*readString*)
readString // beginDefinition;

readString[ file_ ] := Quiet[ readString[ file, ReadByteArray @ file ], $CharacterEncoding::utf8 ];

readString[ file_, bytes_? ByteArrayQ ] := readString[ file, ByteArrayToString @ bytes ];
readString[ file_, string_? StringQ   ] := replaceSpecialCharacters @ fixLineEndings @ string;
readString[ file_, failure_Failure    ] := failure;

readString[ file_, $Failed ] :=
    Module[ { exists, tag, template },
        exists   = TrueQ @ FileExistsQ @ file;
        tag      = If[ exists, "FileUnreadable", "FileNotFound" ];
        template = If[ exists, "Cannot read content from `1`.", "The file `1` does not exist." ];
        Failure[ tag, <| "MessageTemplate" -> template, "MessageParameters" -> { file } |> ]
    ];

readString // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*replaceSpecialCharacters*)
replaceSpecialCharacters // beginDefinition;

replaceSpecialCharacters[ string_String? StringQ ] := StringReplace[
    string,
    special: ("\\[" ~~ LetterCharacter.. ~~ "]") :> ToExpression[ "\""<>special<>"\"" ]
];

replaceSpecialCharacters // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*unreadableFileFailure*)
unreadableFileFailure // beginDefinition;

unreadableFileFailure[ file_ ] :=
    Failure[
        "FileUnreadable",
        <|
            "MessageTemplate" -> "Cannot read content from `1`.",
            "MessageParameters" -> { file }
        |>
    ];

unreadableFileFailure // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*fastFileHash*)
fastFileHash // beginDefinition;
fastFileHash[ file_ ] := fastFileHash[ file, ReadByteArray @ file ];
fastFileHash[ file_, bytes_ByteArray ] := Hash @ bytes;
fastFileHash // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*File Format Utilities*)

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*$fileFormats*)
$fileFormats := ToLowerCase @ Union[ $ImportFormats, $ExportFormats ];

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*fileFormatQ*)
fileFormatQ // beginDefinition;
fileFormatQ[ fmt_String ] := fileFormatQ[ fmt ] = MemberQ[ $fileFormats, ToLowerCase @ fmt ];
fileFormatQ[ _ ] := False
fileFormatQ // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*formatToMIMEType*)
formatToMIMEType // beginDefinition;
formatToMIMEType[ Automatic ] := "application/octet-stream";
formatToMIMEType[ mime_String ] /; StringContainsQ[ mime, "/" ] := ToLowerCase @ mime;
formatToMIMEType[ fmt_String ] := formatToMIMEType[ fmt, FileFormatProperties[ fmt, "MIMETypes" ] ];
formatToMIMEType[ fmt_, _? FailureQ | { } | _FileFormatProperties ] := "application/octet-stream";
formatToMIMEType[ fmt_, { mimeType_String, ___ } ] := mimeType;
formatToMIMEType // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*mimeTypeToFormat*)
mimeTypeToFormat // beginDefinition;
mimeTypeToFormat[ fmt_String ] /; StringFreeQ[ fmt, "/" ] := fmt;
mimeTypeToFormat[ mime_String ] := mimeTypeToFormat @ MIMETypeToFormatList @ mime;
mimeTypeToFormat[ { fmt_String, ___ } ] := fmt;
mimeTypeToFormat[ { } ] := "Binary";
mimeTypeToFormat // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*importDataURI*)
importDataURI // beginDefinition;

importDataURI[ uri_ ] :=
    importDataURI[ uri, Automatic ];

importDataURI[ URL[ uri_String ], fmt_ ] :=
    importDataURI[ uri, fmt ];

importDataURI[ uri_String, fmt0_ ] := Enclose[
    Module[ { info, bytes, fmt, formats, result, $failed },

        info  = ConfirmBy[ uriData @ uri, AssociationQ, "URIData" ];
        bytes = ConfirmBy[ info[ "Data" ], ByteArrayQ, "Data" ];
        fmt   = If[ StringQ @ fmt0, fmt0, Nothing ];

        formats = ConfirmMatch[
            DeleteDuplicates @ Flatten @ { fmt, info[ "Formats" ], Automatic },
            { (Automatic|_String).. },
            "Formats"
        ];

        result = FirstCase[
            formats,
            f_ :> With[ { res = ImportByteArray[ bytes, f ] },
                res /; MatchQ[ res, Except[ _ImportByteArray | _? FailureQ ] ]
            ],
            $failed
        ];

        ConfirmMatch[ result, Except[ $failed ], "Result" ]
    ],
    throwInternalFailure[ importDataURI[ uri, fmt0 ], ## ] &
];

importDataURI // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*uriData*)
uriData // beginDefinition;

uriData[ uri_String ] /; StringMatchQ[ uri, "data:" ~~ ___ ~~ "," ~~ __ ] :=
    uriData @ StringSplit[ StringDelete[ uri, StartOfString~~"data:" ], "," ];

uriData[ { contentType_String, data_String } ] :=
    uriData[ StringSplit[ ToLowerCase @ contentType, ";" ], data ];

uriData[ { data_String } ] :=
    uriData @ { "text/plain;charset=US-ASCII", data };

uriData[ { mimeType_String, "base64" }, data_String ] := <|
    "Formats" -> MIMETypeToFormatList @ mimeType,
    "Data"    -> BaseDecode @ data
|>;

uriData[ { mimeType_String, rule_String, rest___ }, data_String ] /; StringContainsQ[ rule, "=" ] :=
    uriData[ { mimeType <> ";" <> rule, rest }, data ];

uriData[ { mimeType_String }, data_String ] := <|
    "Formats" -> MIMETypeToFormatList @ mimeType,
    "Data"    -> StringToByteArray @ URLDecode @ data
|>;

uriData // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*exportDataURI*)
exportDataURI // beginDefinition;

exportDataURI[ data_, opts: OptionsPattern[ ] ] :=
    With[ { mime = guessExpressionMimeType @ data },
        exportDataURI[ data, mimeTypeToFormat @ mime, mime, opts ]
    ];

exportDataURI[ data_, fmt_String, opts: OptionsPattern[ ] ] :=
    exportDataURI[ data, fmt, formatToMIMEType @ fmt, opts ];

exportDataURI[ data_, fmt_String, mime_String, opts: OptionsPattern[ ] ] := Enclose[
    Module[ { base64 },
        base64 = ConfirmBy[ usingFrontEnd @ ExportString[ data, { "Base64", fmt }, opts ], StringQ, "Base64" ];
        "data:" <> mime <> ";base64," <> StringDelete[ base64, "\n" ]
    ],
    throwInternalFailure
];

exportDataURI // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*guessExpressionMimeType*)
guessExpressionMimeType // beginDefinition;
guessExpressionMimeType[ _? image2DQ            ] := "image/jpeg";
guessExpressionMimeType[ _? graphicsQ           ] := "image/png";
guessExpressionMimeType[ _String? StringQ       ] := "text/plain";
guessExpressionMimeType[ _ByteArray? ByteArrayQ ] := "application/octet-stream";
guessExpressionMimeType[ ___                    ] := "application/vnd.wolfram.wl";
guessExpressionMimeType // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Progress*)
$progressContainer = None;
$progressFraction  = 0.0;
$progressText      = "Please wait\[Ellipsis]";
$defaultProgress   = ProgressIndicator[ Appearance -> "Percolate" ];

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*initializeProgressContainer*)
initializeProgressContainer // beginDefinition;

initializeProgressContainer[ container_Symbol ] := (
    $dynamicTrigger    = 0;
    $progressFraction  = 0.0;
    $progressContainer = HoldComplete @ container[ "DynamicContent" ];

    container = <|
        "DynamicContent" -> $defaultProgress,
        "FullContent"    -> $defaultProgress,
        "UUID"           -> CreateUUID[ ]
    |>
);

initializeProgressContainer // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*setProgressDisplay*)
setProgressDisplay // beginDefinition;

setProgressDisplay[ p: _Integer|_Real ] := Enclose[
    $progressFraction = ConfirmBy[ p, 0.0 <= # <= 1.0 &, "ProgressFraction" ],
    throwInternalFailure
];

setProgressDisplay[ expr_ ] :=
    setProgressDisplay[ expr, 0.0 ];

setProgressDisplay[ expr_, p_ ] :=
    setProgressDisplay[ expr, p, $progressContainer ];

setProgressDisplay[ expr_, p_, HoldComplete[ container_ ] ] := Enclose[
    $progressFraction = ConfirmBy[ p, 0.0 <= # <= 1.0 &, "ProgressFraction" ];
    If[ expr =!= None && ! StringQ @ container,
        WithCleanup[
            container = ConfirmMatch[
                basicProgressPanel[ expr, Dynamic @ $progressFraction ],
                _Deploy,
                "ProgressPanel"
            ],
            $dynamicTrigger++
        ]
    ],
    throwInternalFailure
];

setProgressDisplay[ expr_, _, _ ] :=
    Null;

setProgressDisplay // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*basicProgressPanel*)
basicProgressPanel // beginDefinition;

basicProgressPanel[ expr_, p_ ] := Deploy @ Grid[
    {
        {
            Pane[
                Grid[
                    {
                        {
                            Style[
                                If[ StringQ @ expr,
                                    Row @ { expr, ProgressIndicator[ Appearance -> "Ellipsis" ] },
                                    expr
                                ],
                                "ProgressTitle"
                            ]
                        },
                        {
                            Grid[
                                {
                                    {
                                        Graphics[
                                            {
                                                RGBColor[ 0.26667, 0.61961, 0.96863 ],
                                                Rectangle[ ImageScaled @ { 0, 0 }, ImageScaled @ { p, 1 } ]
                                            },
                                            AspectRatio      -> Full,
                                            Background       -> GrayLevel[ 0.81961 ],
                                            ImageSize        -> { Full, 4 },
                                            PlotRangePadding -> None
                                        ]
                                    }
                                },
                                Alignment -> { Center, Center },
                                Frame     -> None,
                                ItemSize  -> { Automatic, 0 },
                                Spacings  -> { { 0, { }, 0 }, { 0, { }, 0 } }
                            ]
                        }
                    },
                    Alignment  -> { Left, Automatic },
                    Background -> None,
                    Frame      -> All,
                    FrameStyle -> Directive[ 1, GrayLevel[ 0, 0 ] ],
                    Spacings   -> { { 0, { 0 }, 0 }, { 0.6, { -0.2 }, 0.0 } }
                ],
                FrameMargins -> { { 0, 0 }, { 0, 0 } },
                ImageSize    -> { Scaled[ 1 ], Automatic }
            ]
        }
    },
    Frame      -> All,
    FrameStyle -> Directive[ 1, GrayLevel[ 0, 0 ] ],
    Spacings   -> { { 0, { 0 }, 0 }, { 0, { 0 }, 0 } }
];

basicProgressPanel // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*evaluateWithProgress*)
(* This is a workaround for EvaluateWithProgress never printing a progress panel when called normally in a chat: *)
evaluateWithProgress // beginDefinition;
evaluateWithProgress // Attributes = { HoldFirst };
evaluateWithProgress[ args___ ] /; $WorkspaceChat := evaluateWithWorkspaceProgress @ args;
evaluateWithProgress[ args___ ] /; $InlineChat := evaluateWithInlineProgress @ args;
evaluateWithProgress[ args___ ] := evaluateWithProgressContainer[ $progressContainer, args ];
evaluateWithProgress // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*evaluateWithProgressContainer*)
evaluateWithProgressContainer // beginDefinition;
evaluateWithProgressContainer // Attributes = { HoldRest };

evaluateWithProgressContainer[ HoldComplete[ container_ ], args___ ] /; ! StringQ @ container :=
    Module[ { before },
        WithCleanup[
            before = container,
            Progress`EvaluateWithProgress[ args, "Container" :> container, "Delay" -> 0 ],
            PreemptProtect @ If[ ! StringQ @ container, container = before ]
        ]
    ];

evaluateWithProgressContainer[ _, args___ ] :=
    Progress`EvaluateWithProgress[ args, "Delay" -> 0 ];

evaluateWithProgressContainer // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*evaluateWithWorkspaceProgress*)
evaluateWithWorkspaceProgress // beginDefinition;
evaluateWithWorkspaceProgress // Attributes = { HoldFirst };

evaluateWithWorkspaceProgress[ args___ ] :=
    Catch @ Module[ { nbo, cell, container, attached },

        nbo = $evaluationNotebook;
        cell = Last[ Cells[ nbo, CellStyle -> "ChatOutput" ], None ];
        If[ ! MatchQ[ cell, _CellObject ], Throw @ evaluateWithDialogProgress @ args ];

        container = ProgressIndicator[ Appearance -> "Percolate" ];

        attached = AttachCell[
            cell,
            Magnify[
                Pane[
                    Dynamic[ container, Deinitialization :> Quiet @ Remove @ container ],
                    ImageSize -> { Scaled[ 1 ], Automatic }
                ],
                AbsoluteCurrentValue[ nbo, Magnification ]
            ],
            { Left, Bottom },
            Offset[ { 0, -30 }, { 0, 0 } ],
            { Left, Top }
        ];

        WithCleanup[
            Block[ { Progress`AssetsDump`$defaultIndicatorWidth = Scaled[ 0.925 ] },
                Progress`EvaluateWithProgress[
                    args,
                    "Container" :> container,
                    "Delay"     -> 0
                ]
            ],
            NotebookDelete @ attached;
            Quiet @ Remove @ container;
        ]
    ];

evaluateWithWorkspaceProgress // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*evaluateWithInlineProgress*)
evaluateWithInlineProgress // beginDefinition;
evaluateWithInlineProgress // Attributes = { HoldFirst };

evaluateWithInlineProgress[ args___ ] := Enclose[
    Catch @ Module[ { container, cells, inserted },

        container = ProgressIndicator[ Appearance -> "Percolate" ];
        cells = $inlineChatState[ "MessageCells" ];
        inserted = insertInlineProgressIndicator[ Dynamic @ container, cells ];
        If[ ! MatchQ[ inserted, { ___Cell } ], Throw @ evaluateWithDialogProgress @ args ];

        WithCleanup[
            Progress`EvaluateWithProgress[
                args,
                "Container" :> container,
                "Delay"     -> 0
            ],
            ConfirmMatch[ removeInlineProgressIndicator @ cells, { ___Cell }, "Removed" ];
            Quiet @ Remove @ container;
        ]
    ],
    throwInternalFailure
];

evaluateWithInlineProgress // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsubsection::Closed:: *)
(*insertInlineProgressIndicator*)
insertInlineProgressIndicator // beginDefinition;

insertInlineProgressIndicator[ Dynamic[ container_ ], Dynamic[ cells0_Symbol ] ] := Enclose[
    Module[ { cells, cell },
        cells = ConfirmMatch[ cells0, { ___Cell }, "Cells" ];
        cell = Cell[
            BoxData @ assistantMessageBox @ ToBoxes @ Dynamic[
                container,
                Deinitialization :> Quiet @ Remove @ container
            ],
            "ChatOutput",
            "EvaluateWithProgressContainer",
            CellFrame          -> 0,
            PrivateCellOptions -> { "ContentsOpacity" -> 1 }
        ];
        cells0 = Append[ cells, cell ]
    ],
    throwInternalFailure
];

insertInlineProgressIndicator // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsubsection::Closed:: *)
(*removeInlineProgressIndicator*)
removeInlineProgressIndicator // beginDefinition;

removeInlineProgressIndicator[ Dynamic[ cells_Symbol ] ] :=
    cells = DeleteCases[ cells, Cell[ __, "EvaluateWithProgressContainer", ___ ] ];

removeInlineProgressIndicator // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsubsection::Closed:: *)
(*evaluateWithDialogProgress*)
evaluateWithDialogProgress // beginDefinition;
evaluateWithDialogProgress // Attributes = { HoldFirst };

evaluateWithDialogProgress[ args___ ] :=
    Module[ { container, dialog },

        container = ProgressIndicator[ Appearance -> "Percolate" ];

        dialog = CreateDialog[
            Pane[
                Dynamic[ container, Deinitialization :> Quiet @ Remove @ container ],
                ImageMargins -> { { 5, 5 }, { 10, 5 } }
            ],
            WindowTitle -> Dynamic[ $progressText ]
        ];

        WithCleanup[
            Progress`EvaluateWithProgress[
                args,
                "Container" :> container,
                "Delay"     -> 0
            ],
            NotebookClose @ dialog;
            Quiet @ Remove @ container;
        ]
    ];

evaluateWithDialogProgress // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Misc*)

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*contextBlock*)
contextBlock // beginDefinition;
contextBlock // Attributes = { HoldFirst };
contextBlock[ eval_ ] := Block[ { $Context = "Global`", $ContextPath = { "Global`", "System`" } }, eval ];
contextBlock // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*tinyHash*)
tinyHash // beginDefinition;
tinyHash[ e_ ] := tinyHash[ Unevaluated @ e, $tinyHashLength ];
tinyHash[ e_, n_ ] := StringTake[ IntegerString[ Hash @ Unevaluated @ e, 36 ], -n ];
tinyHash // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*$ChatTimingData*)
$ChatTimingData := chatTimingData[ ];

$ChatTimingData /: Unset @ $ChatTimingData := ($timingLog = Internal`Bag[ ]; Null);

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*chatTimingData*)
chatTimingData // beginDefinition;
chatTimingData[ ] := SortBy[ Internal`BagPart[ $timingLog, All ], Lookup[ "AbsoluteTime" ] ]; (* TODO: format this data *)
chatTimingData // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*LogChatTiming*)
LogChatTiming // beginDefinition;
LogChatTiming // Attributes = { HoldFirst, SequenceHold };

LogChatTiming[ tag_String ] := Function[ eval, LogChatTiming[ eval, tag ], HoldAllComplete ];
LogChatTiming[ sym_Symbol ] := LogChatTiming @ Evaluate @ Capitalize @ SymbolName @ sym;
LogChatTiming[ tags_List ] := LogChatTiming @ Evaluate @ StringRiffle[ tags, ":" ];
LogChatTiming[ eval: (h_Symbol)[ ___ ] ] := LogChatTiming[ eval, Capitalize @ SymbolName @ h ];
LogChatTiming[ eval_ ] := LogChatTiming[ eval, "None" ];

LogChatTiming[ eval_, tag_String ] := (
    If[ ! NumberQ @ $chatStartTime, $chatStartTime = AbsoluteTime[ ] ];
    If[ ! StringQ @ $chatEvaluationID, $chatEvaluationID = CreateUUID[ ] ];
    If[ MatchQ[ $timings, _Internal`Bag ],
        logChatTiming[ eval, tag ],
        Block[ { $timings = Internal`Bag[ ] },
            logChatTiming[ eval, tag ]
        ]
    ]
);

LogChatTiming // endExportedDefinition;

$timings   = Internal`Bag[ ];
$timingLog = Internal`Bag[ ];

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*logChatTiming*)
logChatTiming // beginDefinition;
logChatTiming // Attributes = { HoldFirst, SequenceHold };

logChatTiming[ eval_, tag_String ] :=
    Module[ { now, absNow, result, fullTime, innerTimings, usedTime },

        now    = chatTime[ ];
        absNow = AbsoluteTime[ ];

        Block[ { $timings = Internal`Bag[ ] },
            fullTime = First @ AbsoluteTiming[ result = eval ];
            innerTimings = Internal`BagPart[ $timings, All ];
        ];

        usedTime = fullTime - Total @ innerTimings;
        Internal`StuffBag[ $timings, fullTime ];

        Internal`StuffBag[
            $timingLog,
            <|
                "ChatEvaluationCell" -> $ChatEvaluationCell,
                "Tag"                -> tag,
                "UsedTiming"         -> usedTime,
                "FullTiming"         -> fullTime,
                "ChatTime"           -> now,
                "AbsoluteTime"       -> absNow,
                "UUID"               -> $chatEvaluationID
            |>
        ];

        result;
        result
    ];

logChatTiming // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*chatTime*)
chatTime // beginDefinition;
chatTime[ ] := chatTime @ $chatStartTime;
chatTime[ start_Real ] := AbsoluteTime[ ] - start;
chatTime[ _ ] := Missing[ "NotAvailable" ];
chatTime // endDefinition;

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Package Footer*)
addToMXInitialization[
    Scan[ fileFormatQ, $fileFormats ];
];

End[ ];
EndPackage[ ];
