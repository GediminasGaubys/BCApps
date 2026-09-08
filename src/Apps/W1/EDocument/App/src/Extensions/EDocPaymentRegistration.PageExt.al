// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Bank.Payment;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Processing.Message;
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
        addlast(FactBoxes)
        {
            part(EDocStatusFactBox; "E-Doc. Status FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document';
                ShowFilter = false;
            }
            part(EDocMessages; "E-Document Messages FactBox")
            {
                ApplicationArea = Basic, Suite;
                Caption = 'E-Document Messages';
                ShowFilter = false;
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
                    EDocument: Record "E-Document";
                begin
                    EDocument.TryOpenEDocumentForDocument(Rec."Document No.", ApplicablePostingDate, Rec."Source No.");
                end;
            }
        }
    }

    trigger OnOpenPage()
    var
        EDocument: Record "E-Document";
    begin
        EDocumentFeatureInUse := EDocument.IsEDocumentInUse();
    end;

    trigger OnAfterGetRecord()
    var
        EDocumentLookup: Record "E-Document";
    begin
        ApplicablePostingDate := GetApplicablePostingDate();
        EDocumentStatusText := '';
        if EDocumentFeatureInUse then
            EDocumentStatusText := EDocumentLookup.GetLatestStatus(Rec."Document No.", ApplicablePostingDate, Rec."Source No.");
    end;

    trigger OnAfterGetCurrRecord()
    begin
        CurrPage.EDocStatusFactBox.Page.SetDocumentIdentity(Rec."Document No.", ApplicablePostingDate, Rec."Source No.");
        CurrPage.EDocMessages.Page.SetSourceDocumentIdentity(Rec."Document No.", ApplicablePostingDate, Rec."Source No.");
    end;

    local procedure GetApplicablePostingDate() PostingDate: Date
    var
        CustLedgerEntry: Record "Cust. Ledger Entry";
    begin
        if CustLedgerEntry.Get(Rec."Ledger Entry No.") then
            PostingDate := CustLedgerEntry."Posting Date";
    end;

    var
        EDocumentFeatureInUse: Boolean;
        EDocumentStatusText: Text;
        ApplicablePostingDate: Date;
}
