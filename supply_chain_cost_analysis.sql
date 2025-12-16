---1 Clean data---
WITH detailed_cost_components AS (
    SELECT
        shipment_id,
        invoice_month,
        invoice_carrier_code,
        from_country_join_key      AS origin_country,
        to_country_join_key        AS destination_country,
        transactions_id,
        carrier_legs_id,
        
        -- === Group 1: Core Purchase Rate===
        base_rate_amount * exchange_rate AS base_rate_eur,
        fuel_surcharge_amount * exchange_rate AS fuel_surcharge_eur,
        toll_surcharge_amount * exchange_rate AS toll_surcharge_eur,
        green_delivery_fee_amount * exchange_rate AS green_fee_eur,
        label_fee_amount * exchange_rate AS label_fee_eur,

        -- === Group 2: Operational Extras ===
        out_of_area_surcharge_amount * exchange_rate AS out_of_area_eur,
        overweight_or_oversized_amount * exchange_rate AS overweight_eur,
        rerout_and_redeliver_amount * exchange_rate AS reroute_eur,
        packaging_or_repacking_amount * exchange_rate AS packaging_eur,
        signature_surcharge_amount * exchange_rate AS signature_eur,

        -- === Group 3: Audit & Compliance ===
        illegitimate_amount * exchange_rate AS illegitimate_cost_eur, 
        uncategorised_amount * exchange_rate AS uncategorised_cost_eur

    FROM
        `dv_company_prod.supply_chain.carrier_costs_details` --- This SQL script mimics an enterprise environment where data is pre-aggregated via dbt.---
)
, 
---2 Business metrics---
Business_metrics AS (
    SELECT
        invoice_month,
        invoice_carrier_code, 
        origin_country,      
        destination_country,
        CASE 
            WHEN (overweight_eur > 0) THEN 'oversized' ELSE 'standard' END
        AS size_type,

        
        COUNT(DISTINCT shipment_id) AS total_shipments,
        COUNT(DISTINCT transactions_id) AS count_transactions,
        COUNT(DISTINCT carrier_legs_id) AS count_carrier_legs,

        SUM(
            base_rate_eur + 
            fuel_surcharge_eur + 
            toll_surcharge_eur + 
            label_fee_eur + 
            green_fee_eur
        ) AS total_purchase_rate_eur,

        SUM(
            out_of_area_eur + 
            overweight_eur + 
            reroute_eur + 
            packaging_eur + 
            signature_eur 
        ) AS total_extra_costs_eur,
        
        SUM(illegitimate_cost_eur+reroute_eur+packaging_eur) AS total_risk_eur,

        SUM(
            base_rate_eur + fuel_surcharge_eur + toll_surcharge_eur + label_fee_eur + green_fee_eur + 
            out_of_area_eur + overweight_eur + reroute_eur + packaging_eur + signature_eur + 
            illegitimate_cost_eur + 
            uncategorised_cost_eur
        ) AS total_costs_eur,

        ---cost per carrier leg---
        SAFE_DIVIDE(SUM(overweight_eur), SUM(count_carrier_legs)),
        SAFE_DIVIDE(SUM(base_rate_eur),SUM(count_carrier_legs)),
        SAFE_DIVIDE(SUM(fuel_surcharge_eur), SUM(count_carrier_legs)),
        SAFE_DIVIDE(SUM(total_costs_eur),SUM(count_carrier_legs)),
        SAFE_DIVIDE(SUM(illegitimate_cost_eur),SUM(count_carrier_legs)),
        ---cost per transaction---
        SAFE_DIVIDE(SUM(overweight_eur), SUM(count_transactions)),
        SAFE_DIVIDE(SUM(base_rate_eur),SUM(count_transactions)),
        SAFE_DIVIDE(SUM(fuel_surcharge_eur), SUM(count_transactions)),
        SAFE_DIVIDE(SUM(total_costs_eur),SUM(count_transactions)),
        SAFE_DIVIDE(SUM(illegitimate_cost_eur),SUM(count_transactions)),

        AVG(out_of_area_eur),
        AVG(overweight_eur),
        AVG(reroute_eur),
        AVG(packaging_eur),
        AVG(signature_eur)

       

    FROM
        detailed_cost_components 
    
    GROUP BY
        1, 2, 3, 4, 5
    )

    SELECT 
        invoice_month,
        invoice_carrier_code, 
        origin_country,      
        destination_country,
        size_type,
    
        SAFE_DIVIDE(total_risk_eur, total_costs_eur) AS risk_percentage   

    FROM Business_metrics
    where invoice_month >= DATE_SUB(CURRENT_DATE(), INTERVAL 3 month);
 
