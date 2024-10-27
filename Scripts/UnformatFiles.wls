#!/usr/bin/env wolframscript

BeginPackage[ "Wolfram`ChatbookScripts`" ];

If[ ! TrueQ @ $loadedDefinitions, Get @ FileNameJoin @ { DirectoryName @ $InputFileName, "Common.wl" } ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Initialization*)
Needs[ "Wolfram`PacletCICD`" -> "cicd`" ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Rename Default Stylesheet*)
(* The default stylesheet is originally saved with the name ChatbookDefault.nb to make development easier. This is
   allows faster turnarounds when testing, since you do not need to quit the FE and delete the existing stylesheet
   in order to build a new one. However, this means that the stylesheet needs to be renamed to Default.nb when building
   the paclet. We do it here, since we are not using the FE when running the build script.
*)
cFile @ RenameFile[
    cFile @ FileNameJoin @ { $pacletDir, "FrontEnd", "StyleSheets", "ChatbookDefault.nb" },
    FileNameJoin @ { $pacletDir, "FrontEnd", "StyleSheets", "Default.nb" },
    OverwriteTarget -> True
];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Definitions*)

(* ::**************************************************************************************************************:: *)
(* ::Subsection::Closed:: *)
(*unformat*)
unformat[ file_ ] :=
    Enclose @ Module[ { nb, exported },
        nb = ConfirmMatch[ Import[ file, "NB" ], _Notebook, "Import" ];
        exported = ConfirmBy[ Export[ file, nb, "NB" ], FileExistsQ, "Export" ];
        ConfirmAssert[ StringContainsQ[ Import[ file, "String" ], "(* Internal cache information *)" ], "CacheCheck" ];
        cicd`ConsoleLog[ "    "<>exported ];
        exported
    ];

(* ::**************************************************************************************************************:: *)
(* ::Section::Closed:: *)
(*Run*)
files = cicd`ScriptConfirmMatch[
    FileNames[ "*.nb", FileNameJoin @ { $pacletDir, "FrontEnd" }, Infinity ],
    { __String }
];

cicd`ConsoleLog[ "Unformatting " <> ToString @ Length @ files <> " files..." ];

result = cicd`ScriptConfirmMatch[ unformat /@ files, { __String } ];

EndPackage[ ];

Wolfram`ChatbookScripts`result