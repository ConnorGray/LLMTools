(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Package Header*)
BeginPackage[ "Wolfram`Chatbook`" ];

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Declare Symbols*)
`$ChatContextCellStyles;
`$ChatInputPost;
`$ChatSystemPre;
`$DefaultChatInputPost;
`$DefaultChatSystemPre;
`ChatbookAction;
`CreateChatNotebook;

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Begin Private Context*)
Begin[ "`Private`" ];

(* Avoiding context aliasing due to bug 434990: *)
Needs[ "GeneralUtilities`" -> None ];

(* Clear existing definitions *)
GeneralUtilities`UnprotectAndClearAll @ Evaluate[ # <> "*" & /@ Contexts[ "Wolfram`Chatbook`*" ] ];

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*Usage Messages*)
GeneralUtilities`SetUsage[ CreateChatNotebook, "\
CreateChatNotebook[] creates an empty chat notebook and opens it in the front end.\
" ];

GeneralUtilities`SetUsage[ $ChatSystemPre, "\
$ChatSystemPre is a string that is prepended to the beginning of a chat input as the \"system\" role.
Overriding this value may cause some Chatbook functionality to behave unexpectedly.\
" ];

(* TODO: Rename this to $ChatUserPost *)
GeneralUtilities`SetUsage[ $ChatInputPost, "\
$ChatInputPost is a string that is appended to the end of a chat input.\
" ];

GeneralUtilities`SetUsage[ $DefaultChatSystemPre, "\
$DefaultChatSystemPre is the default value of $ChatSystemPre\
" ];

GeneralUtilities`SetUsage[ $DefaultChatInputPost, "\
$ChatInputPost is the default value of $ChatInputPost\
" ];

GeneralUtilities`SetUsage[ $ChatContextCellStyles, "\
$ChatContextCellStyles specifies additional cell styles to include as context to a chat input.
Cells with one of the built-in chat cell styles are always included as context.\
" ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Load Files*)
Block[ { $ContextPath },
    Get[ "Wolfram`Chatbook`Debug`"              ];
    Get[ "Wolfram`Chatbook`ErrorUtils`"         ];
    Get[ "Wolfram`Chatbook`Errors`"             ];
    Get[ "Wolfram`Chatbook`CreateChatNotebook`" ];
    Get[ "Wolfram`Chatbook`Serialization`"      ];
    Get[ "Wolfram`Chatbook`Streaming`"          ];
    Get[ "Wolfram`Chatbook`Utils`"              ];
    Get[ "Wolfram`Chatbook`UI`"                 ];
    Get[ "Wolfram`Chatbook`Actions`"            ];
];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Set Definitions*)

(* This preprompting to wrap code in ``` is necessary for the parsing of code
   blocks into printed output cells to work. *)
$DefaultChatSystemPre  = "Wrap any code using ```. Tag code blocks with the name of the programming language.";
$DefaultChatInputPost  = "";
$ChatSystemPre         = $DefaultChatSystemPre;
$ChatInputPost         = $DefaultChatInputPost;
$ChatContextCellStyles = <| |>;

Protect @ { $DefaultChatSystemPre, $DefaultChatInputPost };

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Package Footer*)
End[ ];
EndPackage[ ];
