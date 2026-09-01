// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Purchases.Payables;

using Microsoft.eServices.EDocument;

pageextension 6112 "E-Doc. Vendor Ledger Entries" extends "Vendor Ledger Entries"
{
    layout
    {
        addlast(Control1)
        {
            field(EDocumentStatus; EDocumentStatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document Status';
                ToolTip = 'Specifies the status of the latest electronic document linked to this record. Hidden by default; add it via Personalize to make it visible.';
                Visible = false;
                Editable = false;
            }
        }
    }
    actions
    {
        addafter("&Navigate")
        {
            action("OpenEDocument")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open E-Document';
                Image = Open;
                Scope = Repeater;
                ToolTip = 'Opens the electronic document linked to this ledger entry, if any.';

                trigger OnAction()
                var
                    EDocument: Record "E-Document";
                begin
                    EDocument.TryOpenEDocumentForDocument(Rec."Document No.", Rec."Posting Date", Rec."Vendor No.");
                end;
            }
        }
        addlast(Category_Process)
        {
            actionref(OpenEDocument_Promoted; OpenEDocument)
            {
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        EDocumentLookup: Record "E-Document";
    begin
        EDocumentStatusText := EDocumentLookup.GetLatestStatus(Rec."Document No.", Rec."Posting Date", Rec."Vendor No.");
    end;

    var
        EDocumentStatusText: Text;
}
