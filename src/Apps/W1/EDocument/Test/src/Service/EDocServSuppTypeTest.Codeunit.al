// ------------------------------------------------------------------------------------------------
// Copyright (c) Microsoft Corporation. All rights reserved.
// Licensed under the MIT License. See License.txt in the project root for license information.
// ------------------------------------------------------------------------------------------------
namespace Microsoft.eServices.EDocument.Test;

using Microsoft.eServices.EDocument;
using Microsoft.eServices.EDocument.Integration;
using Microsoft.eServices.EDocument.Processing.Import;
using Microsoft.Purchases.Vendor;
using System.TestLibraries.Upgrade;
using System.Upgrade;
using System.Utilities;

codeunit 139898 "E-Doc. Serv. Supp. Type Test"
{
    Subtype = Test;
    TestType = IntegrationTest;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        LibraryEDoc: Codeunit "Library - E-Document";
        LibraryUtility: Codeunit "Library - Utility";
        DocumentTypeNotSupportedForImportErr: Label 'Document type %1 is not permitted for the Incoming direction on E-Document Service %2.', Comment = '%1 - E-Document Type, %2 - E-Document Service Code';
        DocumentTypeNotSupportedForExportErr: Label 'Document type %1 is explicitly restricted from the Outgoing direction on E-Document Service %2.', Comment = '%1 - E-Document Type, %2 - E-Document Service Code';

    [Test]
    procedure SupportedTypesPageShowsAndAllowsEditingDirection()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        SupportedTypesPage: TestPage "E-Doc Service Supported Types";
    begin
        // [SCENARIO] Check that the Supported Types page shows and allows editing Direction.
        // [GIVEN] An existing supported type row with Direction = Incoming
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Credit Memo", Enum::"E-Doc. Supp. Type Direction"::Incoming);
        EDocServiceSupportedType.Get(EDocServiceCode, Enum::"E-Document Type"::"Sales Credit Memo");

        // [WHEN] Opening page "E-Doc Service Supported Types" and changing Direction to Both
        SupportedTypesPage.OpenEdit();
        SupportedTypesPage.GoToRecord(EDocServiceSupportedType);
        Assert.AreEqual(Format(Enum::"E-Doc. Supp. Type Direction"::Incoming), SupportedTypesPage.Direction.Value(), 'Direction should show Incoming.');
        SupportedTypesPage.Direction.SetValue(Enum::"E-Doc. Supp. Type Direction"::Both);
        SupportedTypesPage.Close();

        // [THEN] The row's Direction field reflects Both after the change
        EDocServiceSupportedType.FindFirst();
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Both, EDocServiceSupportedType.Direction, 'Direction should be Both after edit.');
    end;

    [Test]
    [HandlerFunctions('SupportedTypesPageHandler')]
    procedure SupportedTypesActionSeedsDefaultsBeforeNewServiceCloses()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Opening supported types from a new service seeds defaults before the card closes.
        EDocServiceCode := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentServicePage.OpenNew();
        EDocumentServicePage.Code.SetValue(EDocServiceCode);

        EDocumentServicePage.SupportedDocTypes.Invoke();

        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        Assert.RecordCount(EDocServiceSupportedType, 4);
        EDocumentServicePage.Close();
    end;

    [Test]
    procedure ExportBlockedWhenDirectionIsIncomingOnly()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Export must be blocked when a document type is configured for Incoming only.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        Assert.IsFalse(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Sales Invoice"), 'Export should be blocked for Incoming-only direction.');
    end;

    [Test]
    procedure ExportAllowedWhenDirectionIsOutgoingOrBoth()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Export is allowed for Outgoing and for Both.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Credit Memo", Enum::"E-Doc. Supp. Type Direction"::Both);

        Assert.IsTrue(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Sales Invoice"), 'Export should be allowed for Outgoing.');
        Assert.IsTrue(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Sales Credit Memo"), 'Export should be allowed for Both.');
    end;

    [Test]
    procedure RecreateLogsExportErrorWhenDirectionChangedToIncoming()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocumentServiceStatus: Record "E-Document Service Status";
        ErrorMessage: Record "Error Message";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Recreate rechecks the current Outgoing permission before exporting.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);
        this.LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        EDocument."Document Type" := Enum::"E-Document Type"::"Sales Invoice";
        EDocument.Modify();

        EDocExport.Recreate(EDocument, EDocumentService);

        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange(Message, StrSubstNo(DocumentTypeNotSupportedForExportErr, EDocument."Document Type", EDocumentService.Code));
        Assert.IsFalse(ErrorMessage.IsEmpty(), 'Recreate should log the Outgoing-direction restriction.');
        EDocumentServiceStatus.Get(EDocument."Entry No", EDocumentService.Code);
        Assert.AreEqual(Enum::"E-Document Service Status"::"Export Error", EDocumentServiceStatus.Status, 'Recreate should set Export Error.');
    end;

    [Test]
    procedure BatchExportLogsErrorWhenDirectionIsIncomingOnly()
    var
        TempEDocMappingLog: Record "E-Doc. Mapping Log" temporary;
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        EDocumentErrorHelper: Codeunit "E-Document Error Helper";
        TempBlob: Codeunit "Temp Blob";
        EDocumentsErrorCount: Dictionary of [Integer, Integer];
        EDocServiceCode: Code[20];
        ErrorCountBeforeExport: Integer;
    begin
        // [SCENARIO] Batch export rechecks the current Outgoing permission before mapping documents.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);
        this.LibraryEDoc.CreateInboundEDocument(EDocument, EDocumentService);
        EDocument."Document Type" := Enum::"E-Document Type"::"Sales Invoice";
        EDocument.Modify();
        EDocument.SetRecFilter();

        EDocExport.ExportEDocumentBatch(EDocument, EDocumentService, TempEDocMappingLog, TempBlob, EDocumentsErrorCount);

        EDocumentsErrorCount.Get(EDocument."Entry No", ErrorCountBeforeExport);
        Assert.IsTrue(EDocumentErrorHelper.ErrorMessageCount(EDocument) > ErrorCountBeforeExport, 'Batch export should log the Outgoing-direction restriction.');
        Assert.AreEqual(0, TempBlob.Length(), 'Batch export should not create a payload for a restricted type.');
    end;

    [Test]
    procedure ImportBlockedWhenDirectionIsOutgoingOnly()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Import must be blocked when a document type is configured for Outgoing only.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);

        Assert.IsFalse(EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice"), 'Import should be blocked for Outgoing-only direction.');
    end;

    [Test]
    [HandlerFunctions('SupportedTypesPageHandler')]
    procedure IntentionallyEmptySupportedTypesRemainEmpty()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocumentServicePage: TestPage "E-Document Service";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Defaults are initialized only once, so deleting every row remains intentional.
        EDocServiceCode := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentServicePage.OpenNew();
        EDocumentServicePage.Code.SetValue(EDocServiceCode);
        EDocumentServicePage.SupportedDocTypes.Invoke();
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);

        EDocumentServicePage.SupportedDocTypes.Invoke();
        EDocumentServicePage.Close();

        Assert.RecordIsEmpty(EDocServiceSupportedType);
    end;

    [Test]
    procedure V1ImportLogsErrorWhenDocumentTypeIsNotConfigured()
    var
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        ErrorMessage: Record "Error Message";
        Vendor: Record Vendor;
    begin
        // [SCENARIO] A V1 import logs an error when its document type is not configured for the service.
        this.LibraryEDoc.Initialize();
        this.LibraryEDoc.SetupStandardPurchaseScenario(Vendor, EDocumentService, Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::"No Integration", Enum::"E-Document Import Process"::"Version 1.0");
        EDocumentService."Validate Receiving Company" := false;
        EDocumentService.Modify();
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        EDocServiceSupportedType.DeleteAll(false);

        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Finish draft";
        this.LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', TempEDocImportParameters);

        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Error);
        ErrorMessage.SetRange(Message, StrSubstNo(DocumentTypeNotSupportedForImportErr, Enum::"E-Document Type"::"Purchase Invoice", EDocumentService.Code));
        Assert.IsFalse(ErrorMessage.IsEmpty(), 'The missing Incoming-direction configuration should be logged as an error.');
    end;

    [Test]
    procedure V2PrepareDraftLogsErrorWhenDirectionIsOutgoingOnly()
    var
        TempEDocImportParameters: Record "E-Doc. Import Parameters";
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocument: Record "E-Document";
        EDocumentService: Record "E-Document Service";
        ErrorMessage: Record "Error Message";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] A V2 Prepare draft step logs an error when its resolved type is restricted to Outgoing.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"E-Document Format"::"PEPPOL BIS 3.0", Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocumentService."Import Process" := "E-Document Import Process"::"Version 2.0";
        EDocumentService."Read into Draft Impl." := "E-Doc. Read into Draft"::PEPPOL;
        EDocumentService.Modify();
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);

        TempEDocImportParameters."Step to Run" := "Import E-Document Steps"::"Prepare draft";
        Assert.IsFalse(
            this.LibraryEDoc.CreateInboundPEPPOLDocumentToState(EDocument, EDocumentService, 'peppol/peppol-invoice-0.xml', TempEDocImportParameters),
            'Prepare draft should fail when Purchase Invoice is restricted to Outgoing.');

        ErrorMessage.SetRange("Context Record ID", EDocument.RecordId());
        ErrorMessage.SetRange("Message Type", ErrorMessage."Message Type"::Error);
        Assert.IsTrue(ErrorMessage.FindFirst(), 'An error should be logged for an Incoming document restricted to Outgoing.');
        Assert.IsTrue(StrPos(ErrorMessage.Message, 'not permitted for the Incoming direction') > 0, 'The error should explain that the document type is not permitted for the Incoming direction.');
    end;

    [Test]
    procedure UpgradeSupportedTypeDirectionSetsLegacyRowsToBoth()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocumentUpgrade: Codeunit "E-Document Upgrade";
        UpgradeTag: Codeunit "Upgrade Tag";
        UpgradeTagLibrary: Codeunit "Upgrade Tag Library";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] The upgrade preserves existing supported types by setting their direction to Both.
        UpgradeTagLibrary.DeleteUpgradeTag(EDocumentUpgrade.GetUpgradeSupportedTypeDirectionTag(), CopyStr(CompanyName(), 1, 30));
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        EDocumentUpgrade.UpgradeSupportedTypeDirection();

        EDocServiceSupportedType.Get(EDocServiceCode, Enum::"E-Document Type"::"Sales Invoice");
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Both, EDocServiceSupportedType.Direction, 'An existing Outgoing type should be upgraded to Both.');
        EDocServiceSupportedType.Get(EDocServiceCode, Enum::"E-Document Type"::"Purchase Invoice");
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Both, EDocServiceSupportedType.Direction, 'An existing Incoming type should be upgraded to Both.');
        EDocServiceSupportedType.Get(EDocServiceCode, Enum::"E-Document Type"::"Remittance Advice");
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Incoming, EDocServiceSupportedType.Direction, 'A previously unconfigured type should preserve historical inbound-only permission.');
        Assert.IsFalse(EDocServiceSupportedType.Get(EDocServiceCode, Enum::"E-Document Type"::None), 'None should not be inserted as a supported document type.');
        Assert.IsTrue(UpgradeTag.HasUpgradeTag(EDocumentUpgrade.GetUpgradeSupportedTypeDirectionTag()), 'The supported type direction upgrade tag should be set.');

        EDocServiceSupportedType.Get(EDocServiceCode, Enum::"E-Document Type"::"Sales Invoice");
        EDocServiceSupportedType.Direction := Enum::"E-Doc. Supp. Type Direction"::Incoming;
        EDocServiceSupportedType.Modify();
        EDocumentUpgrade.UpgradeSupportedTypeDirection();

        EDocServiceSupportedType.Get(EDocServiceCode, Enum::"E-Document Type"::"Sales Invoice");
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Incoming, EDocServiceSupportedType.Direction, 'A completed migration must not overwrite later direction changes.');
    end;

    [Test]
    procedure ImportUsesFallbackPairDirection()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] The Purchase Order/Purchase Invoice fallback pair applies Direction from whichever row matched.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        Assert.IsTrue(EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Order"), 'Purchase Order should inherit Incoming from the Purchase Invoice fallback row.');
        Assert.IsFalse(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Purchase Order"), 'Purchase Order should not be supported for export via an Incoming-only fallback row.');
    end;

    [Test]
    procedure FallbackPartnerDoesNotOverrideExplicitOwnRowDirection()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Purchase Order has its own explicit row (Outgoing only). Purchase Invoice, its fallback partner,
        // is configured Incoming. The fallback must never override an explicit row on the type actually being
        // queried: Purchase Order stays export-only, even though its partner would otherwise allow import.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Order", Enum::"E-Doc. Supp. Type Direction"::Outgoing);
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice", Enum::"E-Doc. Supp. Type Direction"::Incoming);

        Assert.IsFalse(EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Order"), 'Purchase Order''s own Outgoing-only row must not be overridden by the Purchase Invoice fallback partner.');
        Assert.IsTrue(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Purchase Order"), 'Purchase Order should still be exportable via its own explicit Outgoing row.');
    end;

    [Test]
    procedure ImportBlockedWhenDocumentTypeNotConfigured()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocExport: Codeunit "E-Doc. Export";
        EDocServiceCode: Code[20];
    begin
        // [SCENARIO] Import requires an explicit supported-type row for the Incoming direction.
        EDocServiceCode := this.LibraryEDoc.CreateService(Enum::"Service Integration"::"No Integration");
        EDocumentService.Get(EDocServiceCode);
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.DeleteAll(false);

        Assert.IsFalse(EDocExport.IsDocumentTypeSupportedForImport(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice"), 'Import must be blocked when no row is configured.');
        Assert.IsFalse(EDocExport.IsDocumentTypeSupported(EDocumentService, Enum::"E-Document Type"::"Purchase Invoice"), 'Export must still require an explicit row, unchanged from pre-Direction behavior.');
    end;

    [Test]
    procedure ClosingNewServiceSeedsDefaultsForDefaultFormat()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Closing a new service with the default Data Exchange format seeds its defaults.
        EDocServiceCode := LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentServicePage.OpenNew();
        EDocumentServicePage.Code.SetValue(EDocServiceCode);
        EDocumentServicePage.Close();
        EDocumentService.Get(EDocServiceCode);

        Assert.AreEqual(Enum::"E-Document Format"::"Data Exchange", EDocumentService."Document Format", 'Precondition: format must still be the untouched default.');

        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        Assert.RecordCount(EDocServiceSupportedType, 4);
        EDocServiceSupportedType.SetRange("Source Document Type", Enum::"E-Document Type"::"Sales Invoice");
        Assert.IsTrue(EDocServiceSupportedType.FindFirst(), 'Sales Invoice should be seeded when the new service is closed.');
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, EDocServiceSupportedType.Direction, 'Seeded row should be Outgoing.');
    end;

    [Test]
    procedure PEPPOLBIS30SeedingSetsOutgoingDirectionIncludingRemittanceAdvice()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] Creating a service with PEPPOL BIS 3.0 format seeds direction-aware default rows, including Remittance Advice.
        EDocumentService.Init();
        EDocumentService.Code := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert();

        // [WHEN] Validating Document Format = PEPPOL BIS 3.0
        EDocumentService.Validate("Document Format", Enum::"E-Document Format"::"PEPPOL BIS 3.0");
        EDocumentService.Modify();

        // [THEN] All seeded rows, including Remittance Advice, are Outgoing
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        EDocServiceSupportedType.FindSet();
        repeat
            Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, EDocServiceSupportedType.Direction, 'Seeded row should be Outgoing.');
        until EDocServiceSupportedType.Next() = 0;

        Assert.IsTrue(EDocServiceSupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Remittance Advice"), 'Remittance Advice should be seeded for PEPPOL BIS 3.0.');
    end;

    [Test]
    procedure DataExchangeSeedingSetsOutgoingDirection()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] Creating a service with Data Exchange format seeds direction-aware default rows.
        EDocumentService.Init();
        EDocumentService.Code := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert();

        // [WHEN] Validating Document Format = Data Exchange
        EDocumentService.Validate("Document Format", Enum::"E-Document Format"::"Data Exchange");
        EDocumentService.Modify();

        // [THEN] All seeded rows are Outgoing
        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        EDocServiceSupportedType.FindSet();
        repeat
            Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, EDocServiceSupportedType.Direction, 'Seeded row should be Outgoing.');
        until EDocServiceSupportedType.Next() = 0;
    end;

    [Test]
    procedure DataExchangeSeedingDoesNotWidenPartialConfiguration()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
    begin
        // [SCENARIO] Revalidating Data Exchange on a partially configured service must not add missing defaults.
        EDocumentService.Init();
        EDocumentService.Code := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentService.Insert();
        this.LibraryEDoc.AddEDocServiceSupportedType(EDocumentService, Enum::"E-Document Type"::"Sales Invoice", Enum::"E-Doc. Supp. Type Direction"::Outgoing);

        EDocumentService.Validate("Document Format", Enum::"E-Document Format"::"Data Exchange");
        EDocumentService.Modify();

        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocumentService.Code);
        Assert.RecordCount(EDocServiceSupportedType, 1);
        Assert.IsFalse(EDocServiceSupportedType.Get(EDocumentService.Code, Enum::"E-Document Type"::"Sales Credit Memo"), 'Sales Credit Memo should not be added to an already configured service.');
    end;

    [Test]
    procedure ChangingFreshServiceToCustomFormatRemovesGeneratedDefaults()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Creating a service with a custom format does not seed Data Exchange defaults.
        EDocServiceCode := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentServicePage.OpenNew();
        EDocumentServicePage.Code.SetValue(EDocServiceCode);
        EDocumentServicePage."Export Format".SetValue(Enum::"E-Document Format"::Mock);
        EDocumentServicePage.Close();

        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        Assert.RecordIsEmpty(EDocServiceSupportedType);
    end;

    [Test]
    procedure CreatingPEPPOLBIS30ServiceFromCardSeedsPEPPOLDefaults()
    var
        EDocServiceSupportedType: Record "E-Doc. Service Supported Type";
        EDocumentService: Record "E-Document Service";
        EDocServiceCode: Code[20];
        EDocumentServicePage: TestPage "E-Document Service";
    begin
        // [SCENARIO] Creating a PEPPOL service from the card seeds PEPPOL defaults directly.
        EDocServiceCode := this.LibraryUtility.GenerateRandomCode20(EDocumentService.FieldNo(Code), Database::"E-Document Service");
        EDocumentServicePage.OpenNew();
        EDocumentServicePage.Code.SetValue(EDocServiceCode);
        EDocumentServicePage."Export Format".SetValue(Enum::"E-Document Format"::"PEPPOL BIS 3.0");
        EDocumentServicePage.Close();

        EDocServiceSupportedType.SetRange("E-Document Service Code", EDocServiceCode);
        EDocServiceSupportedType.SetRange("Source Document Type");
        Assert.RecordCount(EDocServiceSupportedType, 5);
        Assert.IsTrue(EDocServiceSupportedType.Get(EDocServiceCode, Enum::"E-Document Type"::"Remittance Advice"), 'Remittance Advice should be seeded for a new PEPPOL service.');
        Assert.AreEqual(Enum::"E-Doc. Supp. Type Direction"::Outgoing, EDocServiceSupportedType.Direction, 'Remittance Advice should be seeded as Outgoing.');
    end;

    [PageHandler]
    procedure SupportedTypesPageHandler(var SupportedTypesPage: TestPage "E-Doc Service Supported Types")
    begin
        SupportedTypesPage.Close();
    end;
}