// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.eServices.EDocument;
using Microsoft.Sales.Receivables;

pageextension 6113 "E-Doc. Payment Registration" extends "Payment Registration"
{
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
}
