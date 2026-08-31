// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.eServices.EDocument;

pageextension 6140 "E-Doc. Fin. Charge Memo" extends "Finance Charge Memo"
{
    actions
    {
        addafter("&Issuing")
        {
            group("E-Document")
            {
                action("OpenEDocument")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Open';
                    Image = Open;
                    ToolTip = 'Opens the related E-Document card.';
                    Enabled = EDocumentExists;

                    trigger OnAction()
                    var
                        EDocument: Record "E-Document";
                    begin
                        EDocument.OpenEDocument(Rec.RecordId());
                    end;
                }
                action("PreviewEDocumentMapping")
                {
                    ApplicationArea = Basic, Suite;
                    Caption = 'Preview E-Document Mapping';
                    Image = ViewDetails;
                    ToolTip = 'Preview E-Document Mapping';
                    trigger OnAction()
                    var
                        FinChargeMemoLine: Record "Finance Charge Memo Line";
                        EDocMapping: Codeunit "E-Doc. Mapping";
                    begin
                        FinChargeMemoLine.SetRange("Document No.", Rec."No.");
                        EDocMapping.PreviewMapping(Rec, FinChargeMemoLine, FinChargeMemoLine.FieldNo("Line No."));
                    end;
                }
            }
        }
    }

    var
        EDocumentExists: Boolean;

    trigger OnAfterGetCurrRecord()
    var
        EDocument: Record "E-Document";
    begin
        EDocumentExists := EDocument.HasEDocument(Rec.RecordId());
    end;
}
