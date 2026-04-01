drop table if exists dm.test_task_answer;

create table dm.test_task_answer as
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
store_data as (
    select
        t.store_format,
        t.store_name,
        t.product_group,
        t.product_name,
        t.month_num,
        t.qty_sold,
        t.sales_k_rub,
        t.cogs_k_rub,
        t.avg_stock_qty,
        t.avg_stock_cost_k_rub,
        (t.sales_k_rub - t.cogs_k_rub) as margin_k_rub,
        case
            when coalesce(t.avg_stock_cost_k_rub, 0) = 0 then null
            else t.cogs_k_rub / t.avg_stock_cost_k_rub
        end as turnover_ratio
    from ods.test_task t
    inner join top_store s
        on t.store_name = s.store_name
),
sep_margin as (
    select
        product_name,
        product_group,
        sum(sales_k_rub) as sales_sep_k_rub,
        sum(cogs_k_rub) as cogs_sep_k_rub,
        sum(margin_k_rub) as margin_sep_k_rub
    from store_data
    where month_num = 9
    group by product_name, product_group
),
abc_base as (
    select
        product_name,
        product_group,
        sales_sep_k_rub,
        cogs_sep_k_rub,
        margin_sep_k_rub,
        sum(margin_sep_k_rub) over () as total_margin_sep_k_rub,
        sum(margin_sep_k_rub) over (
            order by margin_sep_k_rub desc, product_name
            rows between unbounded preceding and current row
        ) as cum_margin_sep_k_rub
    from sep_margin
),
abc_result as (
    select
        product_name,
        product_group,
        sales_sep_k_rub,
        cogs_sep_k_rub,
        margin_sep_k_rub,
        case
            when total_margin_sep_k_rub = 0 then null
            else margin_sep_k_rub / total_margin_sep_k_rub
        end as margin_share,
        case
            when total_margin_sep_k_rub = 0 then null
            else cum_margin_sep_k_rub / total_margin_sep_k_rub
        end as cum_margin_share,
        case
            when total_margin_sep_k_rub = 0 then null
            when cum_margin_sep_k_rub / total_margin_sep_k_rub <= 0.80 then 'A'
            when cum_margin_sep_k_rub / total_margin_sep_k_rub <= 0.95 then 'B'
            else 'C'
        end as abc_category
    from abc_base
),
turnover_aug_sep as (
    select
        product_name,
        product_group,
        max(case when month_num = 8 then turnover_ratio end) as turnover_aug,
        max(case when month_num = 9 then turnover_ratio end) as turnover_sep
    from store_data
    where month_num in (8, 9)
    group by product_name, product_group
),
a_with_worse_turnover as (
    select
        a.product_name,
        a.product_group,
        a.abc_category,
        a.sales_sep_k_rub,
        a.cogs_sep_k_rub,
        a.margin_sep_k_rub,
        a.margin_share,
        a.cum_margin_share,
        t.turnover_aug,
        t.turnover_sep
    from abc_result a
    inner join turnover_aug_sep t
        on a.product_name = t.product_name
       and a.product_group = t.product_group
    where a.abc_category = 'A'
      and t.turnover_aug is not null
      and t.turnover_sep is not null
      and t.turnover_sep < t.turnover_aug
),
profitability_3m as (
    select
        product_name,
        product_group,
        sum(sales_k_rub) as sales_3m_k_rub,
        sum(cogs_k_rub) as cogs_3m_k_rub,
        sum(sales_k_rub - cogs_k_rub) as margin_3m_k_rub,
        case
            when sum(sales_k_rub) = 0 then null
            else (sum(sales_k_rub - cogs_k_rub) / sum(sales_k_rub)) * 100
        end as profitability_3m_pct
    from store_data
    where month_num in (7, 8, 9)
    group by product_name, product_group
),
final_ranked as (
    select
        s.store_name,
        a.product_group,
        a.product_name,
        a.abc_category,
        a.sales_sep_k_rub,
        a.cogs_sep_k_rub,
        a.margin_sep_k_rub,
        round(a.margin_share * 100, 2) as margin_share_pct,
        round(a.cum_margin_share * 100, 2) as cum_margin_share_pct,
        round(a.turnover_aug, 4) as turnover_aug,
        round(a.turnover_sep, 4) as turnover_sep,
        round(p.sales_3m_k_rub, 5) as sales_3m_k_rub,
        round(p.cogs_3m_k_rub, 5) as cogs_3m_k_rub,
        round(p.margin_3m_k_rub, 5) as margin_3m_k_rub,
        round(p.profitability_3m_pct, 2) as profitability_3m_pct,
        row_number() over (
            order by p.profitability_3m_pct desc nulls last, a.product_name
        ) as rn
    from a_with_worse_turnover a
    inner join profitability_3m p
        on a.product_name = p.product_name
       and a.product_group = p.product_group
    cross join top_store s
)
select
    store_name,
    product_group,
    product_name,
    abc_category,
    sales_sep_k_rub,
    cogs_sep_k_rub,
    margin_sep_k_rub,
    margin_share_pct,
    cum_margin_share_pct,
    turnover_aug,
    turnover_sep,
    sales_3m_k_rub,
    cogs_3m_k_rub,
    margin_3m_k_rub,
    profitability_3m_pct
from final_ranked
where rn <= 5
order by profitability_3m_pct desc, product_name;
