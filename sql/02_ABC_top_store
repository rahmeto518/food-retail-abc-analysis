with
store_sales_sep as (
    select
        store_name,
        sum(sales_k_rub) as sales_sep_k_rub
    from ods.test_task
    where month_num = 9
    group by store_name
),
top_store as (
    select store_name
    from store_sales_sep
    order by sales_sep_k_rub desc, store_name
    limit 1
),
sep_margin as (
    select
        t.product_group,
        t.product_name,
        sum(t.sales_k_rub) as sales_sep_k_rub,
        sum(t.cogs_k_rub) as cogs_sep_k_rub,
        sum(t.sales_k_rub - t.cogs_k_rub) as margin_sep_k_rub
    from ods.test_task t
    inner join top_store s
        on t.store_name = s.store_name
    where t.month_num = 9
    group by t.product_group, t.product_name
),
abc_base as (
    select
        product_group,
        product_name,
        sales_sep_k_rub,
        cogs_sep_k_rub,
        margin_sep_k_rub,
        sum(margin_sep_k_rub) over () as total_margin_sep_k_rub,
        sum(margin_sep_k_rub) over (
            order by margin_sep_k_rub desc, product_name
            rows between unbounded preceding and current row
        ) as cum_margin_sep_k_rub
    from sep_margin
)
select
    product_group,
    product_name,
    sales_sep_k_rub,
    cogs_sep_k_rub,
    margin_sep_k_rub,
    round(margin_sep_k_rub / nullif(total_margin_sep_k_rub, 0) * 100, 2) as margin_share_pct,
    round(cum_margin_sep_k_rub / nullif(total_margin_sep_k_rub, 0) * 100, 2) as cum_margin_share_pct,
    case
        when cum_margin_sep_k_rub / nullif(total_margin_sep_k_rub, 0) <= 0.80 then 'A'
        when cum_margin_sep_k_rub / nullif(total_margin_sep_k_rub, 0) <= 0.95 then 'B'
        else 'C'
    end as abc_category
from abc_base
order by margin_sep_k_rub desc, product_name;
