/* Formatted on 8/9/2017 5:16:50 PM (QP5 v5.256.13226.35538) */
SELECT                                                --xep.name LEGAL_ENTITY,
       --hou.name OU,
       xgi.vt_transaction_table,
       --      TO_CHAR (add_months(xgi.accounting_date,12), 'MON-YY') Period,
       TO_CHAR (xgi.accounting_date, 'MON-YY') Period,
       xil.attribute2 description,
       xgi.vt_transaction_table source,
       xih.attribute2 owner,
       (SELECT name
          FROM xle_entity_profiles
         WHERE 1 = 1 AND LEGAL_ENTITY_IDENTIFIER = TO_NUMBER (xih.attribute2))
          Source_Entity,
       xih.attribute3 partner,
       (SELECT name
          FROM xle_entity_profiles
         WHERE 1 = 1 AND LEGAL_ENTITY_IDENTIFIER = TO_NUMBER (xih.attribute3))
          partner_Entity,
       p.segment1,
       p.segment2,
       p.segment3,
       p.segment4,
       p.segment5,
       p.segment6,
       p.segment7,
       p.segment8,
       --      (select concatenated_segments from gl_code_combinations_kfv
       --      where 1=1
       --      and code_combination_id  = (select code_combination_id from xla_ae_lines
       --      where 1=1
       --      and to_char(ae_header_id) = to_char(nvl(xgi.vt_transaction_ref,0))
       --      and application_id = 260
       --      and ACCOUNTING_CLASS_CODE = 'CASH')) ORACLE_accounting,
       xih.invoice_number,
       xil.transaction_ref,
       xih.invoice_date,
       xih.invoice_currency,
       xgi.accounting_date exchange_rate_date,
        NVL (
          (SELECT conversion_rate
             FROM apps.gl_daily_rates
            WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                  AND from_currency = xph.CURRENCY_CODE
                  AND to_currency = 'EUR'
                  AND conversion_date = TRUNC (xgi.accounting_date)),
          1)
          eur_exchng_rate,
        nvl(ROUND (
            p.entered_dr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'EUR'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          -
       nvl(ROUND (
            p.entered_cr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'EUR'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          eur_amount,
       NVL (
          (SELECT conversion_rate
             FROM apps.gl_daily_rates
            WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                  AND from_currency = xph.currency_code
                  AND to_currency = 'GBP'
                  AND conversion_date = TRUNC (xgi.accounting_date)),
          1)
          GBP_exchng_rate,
       nvl(ROUND (
            p.entered_dr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'GBP'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)-
       nvl(ROUND (
            p.entered_cr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'GBP'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          GBP_Amount,
       NVL (
          (SELECT conversion_rate
             FROM apps.gl_daily_rates
            WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                  AND from_currency = xph.CURRENCY_CODE
                  AND to_currency = 'USD'
                  AND conversion_date = TRUNC (xgi.accounting_date)),
          1)
          usd_exchng_rate,
       nvl(ROUND (
            p.entered_dr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'USD'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          -
       nvl(ROUND (
            p.entered_cr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'USD'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          USD_Amount,
       USER_JE_CATEGORY_NAME,
       user_je_source_name
--       xil.*
  --      gjh.name Journal_Name,
  --      gjh.je_header_id JOurnal_header_id
  FROM xxcp.xxcp_ic_inv_header xih,
       xxcp.xxcp_ic_inv_lines xil,
       xxcp.xxcp_gl_interface xgi,
       xxcp_process_history_v xph,
       xxcp_process_history p
 --      gl_je_lines gjl,
 --      gl_je_headers gjh
 WHERE     1 = 1
       AND xih.invoice_header_id = xil.invoice_header_id
       AND xil.transaction_ref = xgi.vt_transaction_ref
--             AND xgi.vt_transaction_ref = '4525'
       AND xil.parent_trx_id = xgi.vt_parent_trx_id
       AND xph.set_of_books_id = xgi.ledger_id
       AND xph.transaction_id = xgi.vt_transaction_id
       --      and xph.process_history_id = xil.process_history_id
       AND xgi.vt_parent_trx_id = xph.parent_trx_id
       AND xph.process_history_id = p.process_history_id
       AND (xih.attribute3 = xgi.segment1)
       AND p.rule_id = 10
       and xph.rule_id = p.rule_id
       and p.attribute_id = xil.attribute_id
--       and p.rule_id = xil.rule_id
       AND xgi.vt_transaction_table = 'VT_MANUAL_JOURNALS'
       AND xgi.accounting_date BETWEEN '01-JUN-2017' AND '30-JUN-2017'
       --       AND xih.invoice_date between :p_from_date and :p_to_date
--       AND xih.customer_tax_reg_id IN (128,
--                                       126,
--                                       112,
--                                       115,
--                                       120,
--                                       101,
--                                       106,
--                                       114)
         and  (xih.attribute2 in ('110',
'140',
'230',
'270',
'300',
'460',
'550',
'590') or xih.attribute3 in ('110',
'140',
'230',
'270',
'300',
'460',
'550',
'590'))
UNION ALL
SELECT                                                --xep.name LEGAL_ENTITY,
       --hou.name OU,
       xgi.vt_transaction_table,
       --      TO_CHAR (add_months(xgi.accounting_date,12), 'MON-YY') Period,
       TO_CHAR (xgi.accounting_date, 'MON-YY') Period,
       'SOURCE' description,
       xgi.vt_transaction_table source,
       xgi.segment1 owner,
       (SELECT name
          FROM xle_entity_profiles
         WHERE 1 = 1 AND LEGAL_ENTITY_IDENTIFIER = TO_NUMBER (xgi.segment1))
          Source_Entity,
       NULL PARTNER,
       NULL PARTNER_ENTITY,
       --      xih.attribute3 partner,
       --      (SELECT name
       --         FROM xle_entity_profiles
       --        WHERE 1 = 1 AND LEGAL_ENTITY_IDENTIFIER = TO_NUMBER (xih.attribute3))
       --         partner_Entity,
       p.segment1,
       p.segment2,
       p.segment3,
       p.segment4,
       p.segment5,
       p.segment6,
       p.segment7,
       p.segment8,
       --      (select concatenated_segments from gl_code_combinations_kfv
       --      where 1=1
       --      and code_combination_id  = (select code_combination_id from xla_ae_lines
       --      where 1=1
       --      and to_char(ae_header_id) = to_char(nvl(xgi.vt_transaction_ref,0))
       --      and application_id = 260
       --      and ACCOUNTING_CLASS_CODE = 'CASH')) ORACLE_accounting,
       NULL invoice_number,
       xgi.vt_transaction_ref transaction_ref,
       xgi.accounting_date invoice_date,
       xgi.currency_code,
       xgi.accounting_date exchange_rate_date,
        NVL (
          (SELECT conversion_rate
             FROM apps.gl_daily_rates
            WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                  AND from_currency = xph.CURRENCY_CODE
                  AND to_currency = 'EUR'
                  AND conversion_date = TRUNC (xgi.accounting_date)),
          1)
          eur_exchng_rate,
        nvl(ROUND (
            p.entered_dr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'EUR'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          -
       nvl(ROUND (
            p.entered_cr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'EUR'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          eur_amount,
       NVL (
          (SELECT conversion_rate
             FROM apps.gl_daily_rates
            WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                  AND from_currency = xph.currency_code
                  AND to_currency = 'GBP'
                  AND conversion_date = TRUNC (xgi.accounting_date)),
          1)
          GBP_exchng_rate,
       nvl(ROUND (
            p.entered_dr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'GBP'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)-
       nvl(ROUND (
            p.entered_cr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'GBP'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          GBP_Amount,
       NVL (
          (SELECT conversion_rate
             FROM apps.gl_daily_rates
            WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                  AND from_currency = xph.CURRENCY_CODE
                  AND to_currency = 'USD'
                  AND conversion_date = TRUNC (xgi.accounting_date)),
          1)
          usd_exchng_rate,
       nvl(ROUND (
            p.entered_dr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'USD'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          -
       nvl(ROUND (
            p.entered_cr
          * NVL (
               (SELECT conversion_rate
                  FROM apps.gl_daily_rates
                 WHERE     conversion_type = xgi.USER_CURRENCY_CONVERSION_TYPE
                       AND from_currency = xph.CURRENCY_CODE
                       AND to_currency = 'USD'
                       AND conversion_date = TRUNC (xgi.accounting_date)),
               1),
          2),0)
          USD_Amount,
       USER_JE_CATEGORY_NAME,
       user_je_source_name
  --      gjh.name Journal_Name,
  --      gjh.je_header_id JOurnal_header_id
  FROM xxcp.xxcp_gl_interface xgi,
       xxcp_process_history_v xph,
       xxcp_process_history p
 --      gl_je_lines gjl,
 --      gl_je_headers gjh
 WHERE     1 = 1
       --      AND xih.invoice_header_id = xil.invoice_header_id
       --      AND xil.transaction_ref = xgi.vt_transaction_ref
--             AND xgi.vt_transaction_ref = '4638'
       --      AND xil.parent_trx_id = xgi.vt_parent_trx_id
       AND xph.set_of_books_id = xgi.ledger_id
       AND xph.transaction_id = xgi.vt_transaction_id
--       and  (xgi.segment1 in ('110','140','230','270','300','460','550','590'))
       --      and xph.process_history_id = xil.process_history_id
       AND xgi.vt_parent_trx_id = xph.parent_trx_id
       AND xph.process_history_id = p.process_history_id
       AND EXISTS
              (SELECT 1
                 FROM xxcp_ic_inv_header xih, xxcp_ic_inv_lines xil
                WHERE     1 = 1
                      AND xih.invoice_header_id = xil.invoice_header_id
                      AND xil.transaction_ref = xgi.vt_transaction_ref
                      AND xil.parent_trx_id = xgi.vt_parent_trx_id
                      AND xih.attribute2 = xgi.segment1)
       AND p.rule_id = 10
       AND xgi.vt_transaction_table = 'VT_MANUAL_JOURNALS'
       AND xgi.accounting_date BETWEEN '01-JUN-2017' AND '30-JUN-2017'
       --       AND xih.invoice_date between :p_from_date and :p_to_date
       


       
       
   