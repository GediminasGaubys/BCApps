// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.Receivables;

pageextension 6113 "E-Doc. Payment Registration" extends "Payment Registration"
{
    layout
    {
        addlast(Control2)
        {
            field(EDocumentStatus; EDocumentStatusText)
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document Status';
                ToolTip = 'Specifies the status of the latest electronic document linked to the customer ledger entry that this payment applies to. Hidden by default; add it via Personalize to make it visible.';
                Visible = false;
                Editable = false;
            }
        }
    }
    actions
    {
        addafter(Navigate)
        {
            action("OpenEDocument")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'Open E-Document';
                Image = Open;
                Scope = Repeater;
                ToolTip = 'Opens the electronic document linked to the customer ledger entry that this payment applies to, if any.';

                trigger OnAction()
                var
                    CustLedgerEntry: Record "Cust. Ledger Entry";
                    EDocument: Record "E-Document";
                    PostingDate: Date;
                begin
                    if CustLedgerEntry.Get(Rec."Ledger Entry No.") then
                        PostingDate := CustLedgerEntry."Posting Date";
                    EDocument.TryOpenEDocumentForDocument(Rec."Document No.", PostingDate, Rec."Source No.");
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        EDocumentLookup: Record "E-Document";
    begin
        EDocumentStatusText := EDocumentLookup.GetLatestStatus(Rec."Document No.", 0D, Rec."Source No.");
    end;

    var
        EDocumentStatusText: Text;
}
