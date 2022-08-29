SELECT
	aa.store_id,
	aa.store_name AS store_name,
	aa.country,
	aa.total_orders,
	aa.gmv,
	aa.total_products,
	aa.store_creation_date,
	aa.theme_id_st,
	c.theme_id_swt,
	c.amount,
	d.default_theme,
	aa.name AS current_theme,
	aa.theme_activation_date,
	aa.store_category_id,
	aa.store_category,
	aa.plan_name,
	aa.payment_done
FROM ((
		SELECT
			a.store_id,
			a.store_name,
			a.country,
			ord_gmv.total_orders,
			ord_gmv.gmv,
			ord_gmv.total_products,
			a.store_creation_date,
			a.theme_id_st,
			a.name,
			a.theme_activation_date,
			a.store_category_id,
			a.store_category,
			b.plan_name,
			a.payment_done
		FROM (
			SELECT
				s.created_at at time zone 'Asia/Kolkata' AS store_creation_date,
				st.store_id,
				s.name AS store_name,
				c.name AS country,
				t.id AS theme_id_st,
				t.name,
				(st.created_at at time zone 'Asia/Kolkata') AS theme_activation_date,
				sc.id AS store_category_id,
				sc.name AS store_category,
				st.payment_done
			FROM
				optimus_storetheme st
			LEFT JOIN optimus_theme t ON st.theme_id = t.id
			LEFT JOIN optimus_store s ON st.store_id = s.id
			LEFT JOIN optimus_country c ON s.country_id = c.id
			LEFT JOIN optimus_store_categories scc ON s.id = scc.store_id
			LEFT JOIN optimus_storecategory sc ON scc.storecategory_id = sc.id
			LEFT JOIN optimus_storemeta sm ON sm.store_id = s.id
			--LEFT JOIN optimus_storecategorytheme sct ON sc.id = sct.category_id
			--LEFT JOIN optimus_theme tt ON sct.theme_id = tt.id
		WHERE
			st.is_active IS TRUE
			--AND sct."default" IS TRUE
			AND sm.test_store IS NOT TRUE) a
	LEFT JOIN (
		SELECT
			p.store_id, o.total_orders, o.GMV, p.total_products
		FROM (
			SELECT
				store_id,
				COUNT(id) AS total_products
			FROM
				optimus_product
			GROUP BY
				store_id) p
		LEFT JOIN (
			SELECT
				store_id,
				COUNT(id) AS total_orders,
				SUM(total_cost) AS GMV
			FROM
				optimus_order
			WHERE
				is_deleted IS FALSE
				AND is_active IS TRUE
				AND parent_id IS NULL
				AND status <> - 1
			GROUP BY
				store_id) o ON p.store_id = o.store_id) ord_gmv ON a.store_id = ord_gmv.store_id
	LEFT JOIN (
		SELECT
			sp.store_id,
			p.name AS plan_name
		FROM
			optimus_storeplan sp
			LEFT JOIN optimus_plan p ON sp.plan_id = p.id
		WHERE
			sp.is_active IS TRUE) b ON a.store_id = b.store_id) aa
	LEFT JOIN (
		SELECT
			store_id, amount, meta ->> 'theme_id' AS theme_id_swt
		FROM
			optimus_storewallettransaction
		WHERE
			reason_type = 'debit_theme'
			AND status = 'completed') c ON aa.store_id = c.store_id
	LEFT JOIN (
		SELECT
			sct.category_id, t.name AS default_theme
		FROM
			optimus_storecategorytheme sct
			LEFT JOIN optimus_theme t ON sct.theme_id = t.id
		WHERE
			sct. "default" IS TRUE
		ORDER BY
			sct.category_id) d ON aa.store_category_id = d.category_id);
