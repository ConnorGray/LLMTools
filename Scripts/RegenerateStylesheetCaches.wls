#!/usr/bin/env wolframscript

BeginPackage[ "Wolfram`ChatbookScripts`" ];
If[ ! TrueQ @ $loadedDefinitions, Get @ FileNameJoin @ { DirectoryName @ $InputFileName, "Common.wl" } ];

(* :!CodeAnalysis::BeginBlock:: *)
(* :!CodeAnalysis::Disable::SuspiciousSessionSymbol:: *)

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Initialization*)
Needs[ "Wolfram`PacletCICD`" -> "cicd`" ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Paths*)

(* The chatbook stylesheet containing all features used for chat-enabled and chat-driven notebooks: *)
$chatbookStylesheetFile = cFile @ FileNameJoin @ { $pacletDir, "FrontEnd", "StyleSheets", "Chatbook.nb" };

(* The default stylesheet is originally saved with the name ChatbookDefault.nb to make development easier. This is
   allows faster turnarounds when testing, since you do not need to quit the FE and delete the existing stylesheet
   in order to build a new one. However, this means that the stylesheet needs to be renamed to Default.nb when building
   the paclet. We do it here, since we are not using the FE when running the build script.
*)
$defaultStylesheetFile  = cFile @ RenameFile[
    cFile @ FileNameJoin @ { $pacletDir, "FrontEnd", "StyleSheets", "ChatbookDefault.nb" },
    FileNameJoin @ { $pacletDir, "FrontEnd", "StyleSheets", "Default.nb" },
    OverwriteTarget -> True
];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Export Stylesheets with Cache Information*)

(* Import both of the stylesheet notebooks: *)
cicd`ConsoleLog @ SequenceForm[ "Importing notebook: ", $chatbookStylesheetFile ];
$chatbookStylesheet = cicd`ScriptConfirmMatch[ contextBlock @ Import[ $chatbookStylesheetFile, "NB" ], _Notebook ];

cicd`ConsoleLog @ SequenceForm[ "Importing notebook: ", $defaultStylesheetFile ];
$defaultStylesheet = cicd`ScriptConfirmMatch[ contextBlock @ Import[ $defaultStylesheetFile,  "NB" ], _Notebook ];

(* Export both stylesheets to remove SaveReadableNotebook formatting and include cache info: *)
cicd`ConsoleLog @ SequenceForm[ "Exporting notebook: ", $chatbookStylesheetFile ];
cFile @ contextBlock @ Export[ $chatbookStylesheetFile, $chatbookStylesheet, "NB" ];

cicd`ConsoleLog @ SequenceForm[ "Exporting notebook: ", $defaultStylesheetFile ];
cFile @ contextBlock @ Export[ $defaultStylesheetFile,  $defaultStylesheet,  "NB" ];

(* :!CodeAnalysis::EndBlock:: *)

EndPackage[ ];

<|
    "Chatbook.nb" -> Wolfram`ChatbookScripts`$chatbookStylesheetFile,
    "Default.nb"  -> Wolfram`ChatbookScripts`$defaultStylesheetFile
|>