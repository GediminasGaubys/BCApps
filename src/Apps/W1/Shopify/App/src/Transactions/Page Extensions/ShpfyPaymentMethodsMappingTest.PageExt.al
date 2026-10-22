// TEMPORARY F1.1 sandbox integration-test entry point. Remove after manual testing.
namespace Microsoft.Integration.Shopify;

pageextension 30433 "Shpfy Mapping Test" extends "Shpfy Payment Methods Mapping"
{
    actions
    {
        addlast(Processing)
        {
            action(TemporaryDiscoverPaymentMethods)
            {
                ApplicationArea = All;
                Caption = '[TEST ONLY] Discover Payment Methods';
                Image = Refresh;
                ToolTip = 'Discovers payment gateways and card companies from recent Shopify orders.';

                trigger OnAction()
                var
                    Shop: Record "Shpfy Shop";
                    DiscoverPaymentMethods: Codeunit "Shpfy Discover Payment Methods";
                    ShopCodeFilter: Text;
                begin
                    ShopCodeFilter := Rec.GetFilter("Shop Code");
                    if ShopCodeFilter = '' then
                        Error(ShopContextRequiredErr);
                    if not Shop.Get(ShopCodeFilter) then
                        Error(ShopNotFoundErr, ShopCodeFilter);

                    DiscoverPaymentMethods.Discover(Shop.Code);
                    CurrPage.Update(false);
                end;
            }
        }
    }

    var
        ShopContextRequiredErr: Label 'Open this page from a Shopify Shop Card to discover payment methods.';
        ShopNotFoundErr: Label 'The Shopify Shop %1 could not be found.', Comment = '%1 = Shopify Shop code';
}