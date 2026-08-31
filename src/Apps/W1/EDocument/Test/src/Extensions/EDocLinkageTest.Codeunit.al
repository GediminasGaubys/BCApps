// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.Foundation.Navigate;
using System.TestLibraries.Utilities;

codeunit 139632 "E-Doc. Linkage Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryVariableStorage: Codeunit "Library - Variable Storage";
        IsInitialized: Boolean;
        WrongValueErr: Label 'Wrong value';
        NoEDocumentForRecordMsg: Label 'No electronic document is linked to this record.';

    #region Tests

    [Test]
    procedure HasEDocumentReturnsTrueWhenLinked()
    var
        EDocument: Record "E-Document";
        LinkedRecordId: RecordId;
    begin
        //[SCENARIO] HasEDocument returns true when an E-Document is linked to the given record id.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document is linked to a specific record id.
        LinkedRecordId := this.CreateEDocumentLinkedToRecord();

        //[WHEN] HasEDocument is called with that record id.
        Assert.IsTrue(EDocument.HasEDocument(LinkedRecordId), this.WrongValueErr);

        //[THEN] Verified in WHEN — the call returned true.
    end;

    [Test]
    procedure HasEDocumentReturnsFalseWhenNotLinked()
    var
        EDocument: Record "E-Document";
        UnlinkedRecordId: RecordId;
    begin
        //[SCENARIO] HasEDocument returns false when no E-Document is linked to the given record id.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] A record id for which no E-Document exists.
        UnlinkedRecordId := this.GetRecordIdWithoutEDocument();

        //[WHEN] HasEDocument is called with that record id.
        //[THEN] It returns false.
        Assert.IsFalse(EDocument.HasEDocument(UnlinkedRecordId), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentReturnsTrueWhenAllIdentitiesMatch()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns true when document no., posting date, and partner all match.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific identity exists.
        this.CreateEDocumentWithIdentity('INV-001', WorkDate(), 'C-001');

        //[WHEN] HasEDocumentForDocument is called with the same identity.
        //[THEN] It returns true.
        Assert.IsTrue(EDocument.HasEDocumentForDocument('INV-001', WorkDate(), 'C-001'), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentReturnsFalseWhenDocumentNoIsEmpty()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns false when the document number is empty, regardless of other data.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific identity exists.
        this.CreateEDocumentWithIdentity('INV-002', WorkDate(), 'C-002');

        //[WHEN] HasEDocumentForDocument is called with an empty document no.
        //[THEN] It returns false.
        Assert.IsFalse(EDocument.HasEDocumentForDocument('', WorkDate(), 'C-002'), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentReturnsFalseOnDifferentPostingDate()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns false when the posting date does not match.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific posting date exists.
        this.CreateEDocumentWithIdentity('INV-003', WorkDate(), 'C-003');

        //[WHEN] HasEDocumentForDocument is called with a different posting date.
        //[THEN] It returns false.
        Assert.IsFalse(EDocument.HasEDocumentForDocument('INV-003', WorkDate() + 1, 'C-003'), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentReturnsFalseOnDifferentPartner()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns false when the partner number does not match.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific partner exists.
        this.CreateEDocumentWithIdentity('INV-004', WorkDate(), 'C-004');

        //[WHEN] HasEDocumentForDocument is called with a different partner.
        //[THEN] It returns false.
        Assert.IsFalse(EDocument.HasEDocumentForDocument('INV-004', WorkDate(), 'C-999'), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentIgnoresPostingDateWhenBlank()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument does not filter on posting date when 0D is passed.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific posting date exists.
        this.CreateEDocumentWithIdentity('INV-005', WorkDate(), 'C-005');

        //[WHEN] HasEDocumentForDocument is called without a posting date filter.
        //[THEN] It returns true because the posting date filter is skipped.
        Assert.IsTrue(EDocument.HasEDocumentForDocument('INV-005', 0D, 'C-005'), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentIgnoresPartnerWhenBlank()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument does not filter on partner when an empty partner no. is passed.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific partner exists.
        this.CreateEDocumentWithIdentity('INV-006', WorkDate(), 'C-006');

        //[WHEN] HasEDocumentForDocument is called without a partner filter.
        //[THEN] It returns true because the partner filter is skipped.
        Assert.IsTrue(EDocument.HasEDocumentForDocument('INV-006', WorkDate(), ''), this.WrongValueErr);
    end;

    [Test]
    procedure HasEDocumentForDocumentMatchesOnlySameDocumentNo()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] HasEDocumentForDocument returns false for a document no. that does not exist even when other E-Documents are present.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific document no. exists.
        this.CreateEDocumentWithIdentity('INV-007', WorkDate(), 'C-007');

        //[WHEN] HasEDocumentForDocument is called with a different document no.
        //[THEN] It returns false.
        Assert.IsFalse(EDocument.HasEDocumentForDocument('INV-999', WorkDate(), 'C-007'), this.WrongValueErr);
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TryOpenEDocumentForDocumentShowsMessageWhenDocumentNoEmpty()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] TryOpenEDocumentForDocument returns false and shows the "no e-document" message when the document no. is empty.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document exists for a different record.
        this.CreateEDocumentWithIdentity('INV-008', WorkDate(), 'C-008');

        //[WHEN] TryOpenEDocumentForDocument is called with an empty document no.
        Assert.IsFalse(EDocument.TryOpenEDocumentForDocument('', WorkDate(), 'C-008'), this.WrongValueErr);

        //[THEN] The "no e-document" message was shown.
        this.AssertNoEDocumentMessageShown();
    end;

    [Test]
    [HandlerFunctions('MessageHandler')]
    procedure TryOpenEDocumentForDocumentShowsMessageWhenNoMatch()
    var
        EDocument: Record "E-Document";
    begin
        //[SCENARIO] TryOpenEDocumentForDocument returns false and shows the "no e-document" message when no E-Document matches.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document exists for a different record.
        this.CreateEDocumentWithIdentity('INV-009', WorkDate(), 'C-009');

        //[WHEN] TryOpenEDocumentForDocument is called with an unmatched document no.
        Assert.IsFalse(EDocument.TryOpenEDocumentForDocument('INV-NOPE', WorkDate(), 'C-009'), this.WrongValueErr);

        //[THEN] The "no e-document" message was shown.
        this.AssertNoEDocumentMessageShown();
    end;

    [Test]
    procedure NavigateHandlerFindEDocumentsInsertsRowWhenMatchExists()
    var
        DocumentEntry: Record "Document Entry" temporary;
        EDocNavigateHandler: Codeunit "E-Doc. Navigate Handler";
    begin
        //[SCENARIO] E-Doc. Navigate Handler.FindEDocuments inserts a Document Entry row for the E-Document table when a match exists.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document with a specific document no. and posting date exists.
        this.CreateEDocumentWithIdentity('INV-010', WorkDate(), 'C-010');

        //[WHEN] FindEDocuments is called with matching filters.
        EDocNavigateHandler.FindEDocuments(DocumentEntry, 'INV-010', Format(WorkDate()));

        //[THEN] A Document Entry row for the E-Document table is present with one record.
        this.AssertDocumentEntryHasEDocumentRow(DocumentEntry, 1);
    end;

    [Test]
    procedure NavigateHandlerFindEDocumentsInsertsNoRowWhenNoMatch()
    var
        DocumentEntry: Record "Document Entry" temporary;
        EDocNavigateHandler: Codeunit "E-Doc. Navigate Handler";
    begin
        //[SCENARIO] E-Doc. Navigate Handler.FindEDocuments does not insert a Document Entry row when no E-Document matches.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] An E-Document exists for a different document no.
        this.CreateEDocumentWithIdentity('INV-011', WorkDate(), 'C-011');

        //[WHEN] FindEDocuments is called with a document no. that does not match.
        EDocNavigateHandler.FindEDocuments(DocumentEntry, 'INV-NOMATCH', Format(WorkDate()));

        //[THEN] No Document Entry row for the E-Document table is inserted.
        this.AssertDocumentEntryHasNoEDocumentRow(DocumentEntry);
    end;

    [Test]
    procedure NavigateHandlerFindEDocumentsCountsAllMatchingRecords()
    var
        DocumentEntry: Record "Document Entry" temporary;
        EDocNavigateHandler: Codeunit "E-Doc. Navigate Handler";
    begin
        //[SCENARIO] E-Doc. Navigate Handler.FindEDocuments reports the total count of matching E-Documents.

        //[GIVEN] Test setup exists.
        this.Initialize();

        //[GIVEN] Two E-Documents with the same document no. and posting date exist.
        this.CreateTwoEDocumentsWithSameIdentity('INV-012', WorkDate(), 'C-012');

        //[WHEN] FindEDocuments is called with matching filters.
        EDocNavigateHandler.FindEDocuments(DocumentEntry, 'INV-012', Format(WorkDate()));

        //[THEN] The Document Entry row for the E-Document table reports two records.
        this.AssertDocumentEntryHasEDocumentRow(DocumentEntry, 2);
    end;

    #endregion

    #region Initialize

    local procedure Initialize()
    var
        EDocument: Record "E-Document";
    begin
        this.LibraryVariableStorage.Clear();
        EDocument.DeleteAll(false);
        if this.IsInitialized then
            exit;
        this.IsInitialized := true;
    end;

    #endregion

    #region Given

    local procedure CreateEDocumentLinkedToRecord() LinkedRecordId: RecordId
    var
        EDocument: Record "E-Document";
    begin
        // Use the E-Document table itself as a stable source of a real RecordId — the linkage logic
        // only checks whether an "E-Document" row references the given RecordId; the target table is
        // irrelevant to the code under test.
        EDocument.Init();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Insert(true);
        LinkedRecordId := EDocument.RecordId();
        EDocument."Document Record ID" := LinkedRecordId;
        EDocument.Modify(false);
    end;

    local procedure GetRecordIdWithoutEDocument() UnlinkedRecordId: RecordId
    var
        EDocument: Record "E-Document";
    begin
        EDocument.Init();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Insert(true);
        UnlinkedRecordId := EDocument.RecordId();
        EDocument.Delete(false);
    end;

    local procedure CreateEDocumentWithIdentity(DocumentNo: Code[20]; PostingDate: Date; PartnerNo: Code[20])
    var
        EDocument: Record "E-Document";
    begin
        EDocument.Init();
        EDocument.Direction := EDocument.Direction::Outgoing;
        EDocument.Insert(true);
        EDocument."Document No." := DocumentNo;
        EDocument."Posting Date" := PostingDate;
        EDocument."Bill-to/Pay-to No." := PartnerNo;
        EDocument.Modify(false);
    end;

    local procedure CreateTwoEDocumentsWithSameIdentity(DocumentNo: Code[20]; PostingDate: Date; PartnerNo: Code[20])
    begin
        this.CreateEDocumentWithIdentity(DocumentNo, PostingDate, PartnerNo);
        this.CreateEDocumentWithIdentity(DocumentNo, PostingDate, PartnerNo);
    end;

    #endregion

    #region Then

    local procedure AssertNoEDocumentMessageShown()
    begin
        Assert.AreEqual(this.NoEDocumentForRecordMsg, this.LibraryVariableStorage.DequeueText(), this.WrongValueErr);
    end;

    local procedure AssertDocumentEntryHasEDocumentRow(var DocumentEntry: Record "Document Entry"; ExpectedCount: Integer)
    begin
        DocumentEntry.SetRange("Table ID", Database::"E-Document");
        Assert.IsTrue(DocumentEntry.FindFirst(), 'Expected a Document Entry row for the E-Document table.');
        Assert.AreEqual(ExpectedCount, DocumentEntry."No. of Records", this.WrongValueErr);
    end;

    local procedure AssertDocumentEntryHasNoEDocumentRow(var DocumentEntry: Record "Document Entry")
    begin
        DocumentEntry.SetRange("Table ID", Database::"E-Document");
        Assert.IsTrue(DocumentEntry.IsEmpty(), 'Expected no Document Entry row for the E-Document table.');
    end;

    #endregion

    [MessageHandler]
    procedure MessageHandler(Message: Text[1024])
    begin
        this.LibraryVariableStorage.Enqueue(Message);
    end;
}
