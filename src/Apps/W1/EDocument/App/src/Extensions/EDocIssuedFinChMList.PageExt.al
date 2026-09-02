// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.Sales.FinanceCharge;

using Microsoft.eServices.EDocument;

pageextension 6153 "E-Doc. Issued Fin. Ch. M. List" extends "Issued Fin. Charge Memo List"
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

    trigger OnAfterGetRecord()
    var
        EDocumentLookup: Record "E-Document";
    begin
        EDocumentStatusText := EDocumentLookup.GetLatestStatus(Rec.RecordId());
    end;

    var
        EDocumentStatusText: Text;
}
