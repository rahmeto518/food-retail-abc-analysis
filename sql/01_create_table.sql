create table ods.test_task (
    store_format text,
    store_name text,
    product_group text,
    product_name text,
    month_num int,
    qty_sold numeric(18,3),
    sales_k_rub numeric(18,5),
    cogs_k_rub numeric(18,5),
    avg_stock_qty numeric(18,3),
    avg_stock_cost_k_rub numeric(18,5)
);

comment on table ods.test_task is
'Тестовое задание: продажи товаров собственного производства food-retail';

comment on column ods.test_task.store_format is
'Формат магазина (Гипер, Супер и т.д.)';

comment on column ods.test_task.store_name is
'Наименование магазина';

comment on column ods.test_task.product_group is
'Товарная группа';

comment on column ods.test_task.product_name is
'Номенклатура товара собственного производства';

comment on column ods.test_task.month_num is
'Номер месяца: 7 = июль, 8 = август, 9 = сентябрь';

comment on column ods.test_task.qty_sold is
'Количество проданного товара, шт';

comment on column ods.test_task.sales_k_rub is
'Сумма продаж, тыс. руб.';

comment on column ods.test_task.cogs_k_rub is
'Себестоимость продаж, тыс. руб.';

comment on column ods.test_task.avg_stock_qty is
'Среднедневной остаток на конец дня, шт';

comment on column ods.test_task.avg_stock_cost_k_rub is
'Среднедневная себестоимость остатка на конец дня, тыс. руб.';
