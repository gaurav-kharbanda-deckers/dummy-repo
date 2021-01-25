DECLARE
   CURSOR get_orders_c
   IS
      SELECT tmp.*,
             (SELECT user_id
                FROM apps.fnd_user
               WHERE user_name = 'BATCH.O2F')
                user_id,
             (SELECT frv.responsibility_id
                FROM apps.fnd_profile_options_vl fpo,
                     apps.fnd_profile_option_values fpov,
                     apps.fnd_responsibility_vl frv
               WHERE     frv.application_id = 660
                     AND fpov.level_value = frv.responsibility_id
                     AND fpo.profile_option_id = fpov.profile_option_id
                     AND fpo.user_profile_option_name = 'MO: Operating Unit'
                     AND fpov.profile_option_id = fpo.profile_option_id
                     AND fpov.profile_option_value = TO_CHAR (tmp.org_id)
                     AND frv.responsibility_key LIKE 'DO_OM_USER%')
                resp_id,
             (SELECT application_id
                FROM apps.fnd_application_tl
               WHERE     language = USERENV ('LANG')
                     AND application_name = 'Order Management')
                appl_id
        FROM ssiricilla.xxd_mtd_om_ln_calc_tax_0108_t tmp
       WHERE 1=1
         AND batch_id = 4
         AND status = 'N'
       ORDER BY tmp.header_id;

   TYPE line_rec IS RECORD
   (
      line_id          NUMBER,
      line_header_id   NUMBER
   );

   TYPE header_rec IS RECORD
   (
      header_id   NUMBER,
      org_id      NUMBER,
      user_id     NUMBER,
      resp_id     NUMBER,
      appl_id     NUMBER
   );

   TYPE header_list IS TABLE OF header_rec
      INDEX BY BINARY_INTEGER;

   TYPE line_list IS TABLE OF line_rec
      INDEX BY BINARY_INTEGER;

   header_ids                      header_list;
   line_ids                        line_list;
   current_header_id               NUMBER;
   current_line_id                 NUMBER;
   l_header_rec                    oe_order_pub.header_rec_type;
   l_line_tbl                      oe_order_pub.line_tbl_type;
   lc_return_status                VARCHAR2 (2000);
   lc_msg_data                     VARCHAR2 (1000);
   lc_error_message                VARCHAR2 (4000);
   l_line_tbl_index                NUMBER := 0;
   ln_msg_count                    NUMBER := 0;
   ln_msg_index_out                NUMBER := 0;
   l_action_request_tbl            oe_order_pub.request_tbl_type;
   x_header_rec                    oe_order_pub.header_rec_type;
   x_header_val_rec                oe_order_pub.header_val_rec_type;
   x_header_adj_tbl                oe_order_pub.header_adj_tbl_type;
   x_header_adj_val_tbl            oe_order_pub.header_adj_val_tbl_type;
   x_header_price_att_tbl          oe_order_pub.header_price_att_tbl_type;
   x_header_adj_att_tbl            oe_order_pub.header_adj_att_tbl_type;
   x_header_adj_assoc_tbl          oe_order_pub.header_adj_assoc_tbl_type;
   x_header_scredit_tbl            oe_order_pub.header_scredit_tbl_type;
   x_header_scredit_val_tbl        oe_order_pub.header_scredit_val_tbl_type;
   x_line_tbl                      oe_order_pub.line_tbl_type;
   x_line_val_tbl                  oe_order_pub.line_val_tbl_type;
   x_line_adj_tbl                  oe_order_pub.line_adj_tbl_type;
   x_line_adj_val_tbl              oe_order_pub.line_adj_val_tbl_type;
   x_line_price_att_tbl            oe_order_pub.line_price_att_tbl_type;
   x_line_adj_att_tbl              oe_order_pub.line_adj_att_tbl_type;
   x_line_adj_assoc_tbl            oe_order_pub.line_adj_assoc_tbl_type;
   x_line_scredit_tbl              oe_order_pub.line_scredit_tbl_type;
   x_line_scredit_val_tbl          oe_order_pub.line_scredit_val_tbl_type;
   x_lot_serial_tbl                oe_order_pub.lot_serial_tbl_type;
   x_lot_serial_val_tbl            oe_order_pub.lot_serial_val_tbl_type;
   x_action_request_tbl            oe_order_pub.request_tbl_type;

   l_day_of_date_without_add_sec   NUMBER;
   l_day_of_date_with_add_sec      NUMBER;
   l_tax_date_with_added_sec       DATE;
   l_tax_date_with_sub_sec         DATE;
BEGIN
   DBMS_OUTPUT.enable (NULL);

   DBMS_OUTPUT.put_line (RPAD ('=', 100, '='));

   -- Populate Header and Line Arrays
   FOR i IN get_orders_c
   LOOP
      -- Headers
      header_ids (i.header_id).header_id := i.header_id;
      header_ids (i.header_id).org_id := i.org_id;
      header_ids (i.header_id).user_id := i.user_id;
      header_ids (i.header_id).resp_id := i.resp_id;
      header_ids (i.header_id).appl_id := i.appl_id;
      -- Lines
      line_ids (i.line_id).line_id := i.line_id;
      line_ids (i.line_id).line_header_id := i.header_id;
   END LOOP;

   current_header_id := header_ids.FIRST;

   FOR headers_rec IN 1 .. header_ids.COUNT
   LOOP
      mo_global.init ('ONT');
      mo_global.set_policy_context ('S',
                                    header_ids (current_header_id).org_id);
     -- oe_msg_pub.delete_msg;
      --oe_msg_pub.initialize;
      fnd_global.apps_initialize (
         user_id        => header_ids (current_header_id).user_id,
         resp_id        => header_ids (current_header_id).resp_id,
         resp_appl_id   => header_ids (current_header_id).appl_id);
      DBMS_OUTPUT.put_line (
            'Processing Header ID = '
         || header_ids (current_header_id).header_id);

      lc_error_message := NULL;
      lc_return_status := NULL;
      ln_msg_count := 0;
      lc_msg_data := NULL;
      l_line_tbl_index := 0;

      -- Flush the data
      l_header_rec := oe_order_pub.g_miss_header_rec;
      l_line_tbl := oe_order_pub.g_miss_line_tbl;
      l_action_request_tbl := oe_order_pub.g_miss_request_tbl;

      -- Header
      l_header_rec.header_id := header_ids (current_header_id).header_id;
      l_header_rec.org_id := header_ids (current_header_id).org_id;
      l_header_rec.operation := oe_globals.g_opr_update;

      current_line_id := line_ids.FIRST;

      FOR lines_rec IN 1 .. line_ids.COUNT
      LOOP
         l_day_of_date_without_add_sec := NULL;
         l_day_of_date_with_add_sec := NULL;
         l_tax_date_with_added_sec := NULL;
         l_tax_date_with_sub_sec := NULL;

         -- Fetch Only Current Header IDs
         IF line_ids (current_line_id).line_header_id =
               header_ids (current_header_id).header_id
         THEN
            -- Lines
            l_line_tbl_index := l_line_tbl_index + 1;
            l_line_tbl (l_line_tbl_index) := oe_order_pub.g_miss_line_rec;
            l_line_tbl (l_line_tbl_index).header_id :=
               header_ids (current_header_id).header_id;
            l_line_tbl (l_line_tbl_index).org_id :=
               header_ids (current_header_id).org_id;
            l_line_tbl (l_line_tbl_index).line_id :=
               line_ids (current_line_id).line_id;
            l_line_tbl (l_line_tbl_index).tax_code := NULL;--FND_API.G_MISS_CHAR;
           -- l_line_tbl (l_line_tbl_index).ordered_quantity := 14; --- Remove it
            l_line_tbl (l_line_tbl_index).operation := oe_globals.g_opr_update;

--             Recalculate Tax

            SELECT EXTRACT (DAY FROM tax_date),
                   EXTRACT (DAY FROM tax_date + INTERVAL '1' SECOND),
                   (tax_date + INTERVAL '1' SECOND),
                   (tax_date - INTERVAL '1' SECOND)
              INTO l_day_of_date_without_add_sec,
                   l_day_of_date_with_add_sec,
                   l_tax_date_with_added_sec,
                   l_tax_date_with_sub_sec
              FROM oe_order_lines_all
             WHERE line_id = line_ids (current_line_id).line_id;


            /* Begin: Block to add or subract one sec to the existing tax date such that
          existing  tax date wont change to next day.
          for instance: 12-Dec-2018 11:59:59PM. in this case adding sec to the existing
          tax date will change the day to 13-Dec and might cause different tax rate.
           */
--             Update Tax Date to recalculate the Tax
            IF l_day_of_date_without_add_sec = l_day_of_date_with_add_sec
            THEN               -- day remains same even after adding sec to it
               l_line_tbl (l_line_tbl_index).tax_date :=
                  l_tax_date_with_added_sec;
            ELSE
               --tax date is changing by adding sec to it. subract sec from the current tax date
               l_line_tbl (l_line_tbl_index).tax_date :=
                  l_tax_date_with_sub_sec;
            END IF;
         END IF;

         current_line_id := line_ids.NEXT (current_line_id);
      END LOOP;

      oe_order_pub.process_order (
         p_api_version_number       => 1.0,
         p_init_msg_list            => fnd_api.g_false,
         p_return_values            => fnd_api.g_false,
         p_action_commit            => fnd_api.g_false,
         x_return_status            => lc_return_status,
         x_msg_count                => ln_msg_count,
         x_msg_data                 => lc_msg_data,
         p_header_rec               => l_header_rec,
         p_line_tbl                 => l_line_tbl,
         p_action_request_tbl       => l_action_request_tbl,
         x_header_rec               => x_header_rec,
         x_header_val_rec           => x_header_val_rec,
         x_header_adj_tbl           => x_header_adj_tbl,
         x_header_adj_val_tbl       => x_header_adj_val_tbl,
         x_header_price_att_tbl     => x_header_price_att_tbl,
         x_header_adj_att_tbl       => x_header_adj_att_tbl,
         x_header_adj_assoc_tbl     => x_header_adj_assoc_tbl,
         x_header_scredit_tbl       => x_header_scredit_tbl,
         x_header_scredit_val_tbl   => x_header_scredit_val_tbl,
         x_line_tbl                 => x_line_tbl,
         x_line_val_tbl             => x_line_val_tbl,
         x_line_adj_tbl             => x_line_adj_tbl,
         x_line_adj_val_tbl         => x_line_adj_val_tbl,
         x_line_price_att_tbl       => x_line_price_att_tbl,
         x_line_adj_att_tbl         => x_line_adj_att_tbl,
         x_line_adj_assoc_tbl       => x_line_adj_assoc_tbl,
         x_line_scredit_tbl         => x_line_scredit_tbl,
         x_line_scredit_val_tbl     => x_line_scredit_val_tbl,
         x_lot_serial_tbl           => x_lot_serial_tbl,
         x_lot_serial_val_tbl       => x_lot_serial_val_tbl,
         x_action_request_tbl       => x_action_request_tbl);

      DBMS_OUTPUT.put_line ('API Status = ' || lc_return_status);
      --DBMS_OUTPUT.put_line ('Error Count = ' || ln_msg_count);
      --DBMS_OUTPUT.put_line ('MSG Data = ' || lc_msg_data);

      IF lc_return_status <> fnd_api.g_ret_sts_success
      THEN
      ROLLBACK;
         FOR i IN 1 .. oe_msg_pub.count_msg
         LOOP
            oe_msg_pub.get (p_msg_index       => i,
                            p_encoded         => fnd_api.g_false,
                            p_data            => lc_msg_data,
                            p_msg_index_out   => ln_msg_index_out);
            lc_error_message := lc_error_message || lc_msg_data;
         END LOOP;

         DBMS_OUTPUT.put_line ('API Error Message = ' || lc_error_message);
         else
         commit;
      END IF;

      UPDATE ssiricilla.xxd_mtd_om_ln_calc_tax_0108_t
         SET status = lc_return_status, error_msg = lc_error_message
       WHERE header_id = header_ids (current_header_id).header_id
	     AND batch_id = 4;

      COMMIT;

      --COMMIT;
      DBMS_OUTPUT.put_line (RPAD ('=', 100, '='));
      current_header_id := header_ids.NEXT (current_header_id);
   END LOOP;
EXCEPTION
   WHEN OTHERS
   THEN
      ROLLBACK;
      lc_error_message := SUBSTR (SQLERRM, 1, 4000);
      DBMS_OUTPUT.put_line ('EXCEPTION = ' || lc_error_message);
END;
/