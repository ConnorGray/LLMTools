#!/usr/bin/env wolframscript

BeginPackage[ "Wolfram`ChatbookScripts`" ];
If[ ! TrueQ @ $loadedDefinitions, Get @ FileNameJoin @ { DirectoryName @ $InputFileName, "Common.wl" } ];

(* :!CodeAnalysis::BeginBlock:: *)
(* :!CodeAnalysis::Disable::SuspiciousSessionSymbol:: *)

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Initialization*)
Needs[ "Wolfram`PacletCICD`" -> "cicd`" ];

removeExistingStylesheet[ file_ ] :=
    If[ FileExistsQ @ file,
        cicd`ConsoleLog @ SequenceForm[ "Removing existing stylesheet file: ", file ];
        cicd`ScriptConfirm @ DeleteFile @ file;
        cicd`ScriptConfirmBy[ file, Not@*FileExistsQ ],
        file
    ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Paths*)

(* The chatbook stylesheet containing all features used for chat-enabled and chat-driven notebooks: *)
$chatbookStylesheetFile = cStr @ FileNameJoin @ { $pacletDir, "FrontEnd", "StyleSheets", "Chatbook.nb" };
$defaultStylesheetFile  = cStr @ FileNameJoin @ { $pacletDir, "FrontEnd", "StyleSheets", "ChatbookDefault.nb" };

(* The package file containing the definitions for building stylesheets: *)
$builderFile = cFile @ FileNameJoin @ { $pacletDir, "Developer", "StylesheetBuilder.wl" };

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Build Stylesheet*)

(* Remove existing stylesheet files if they exist: *)
removeExistingStylesheet @ $chatbookStylesheetFile;
removeExistingStylesheet @ $defaultStylesheetFile;

(* Build the stylesheets: *)
cicd`ConsoleLog[ "Building stylesheets..." ];
contextBlock @ UsingFrontEnd[
    cicd`ScriptConfirm @ CheckAbort[ Get @ $builderFile, $Failed ];
    result = <|
        "Chatbook" -> cFile @ Wolfram`ChatbookStylesheetBuilder`BuildChatbookStylesheet[ ],
        "Default"  -> cFile @ Wolfram`ChatbookStylesheetBuilder`BuildDefaultStylesheet[ ]
    |>;
];

cicd`ConsoleLog @ SequenceForm[ "Built stylesheets: ", result ];

(* :!CodeAnalysis::EndBlock:: *)

EndPackage[ ];

Wolfram`ChatbookScripts`result