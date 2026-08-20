/* ================================================================
   SUPPLY CHAIN COST vs QUALITY ANALYSIS — SQL PORTFOLIO PROJECT
   ================================================================
   Dataset : Supply Chain Analysis (Kaggle)
             https://www.kaggle.com/datasets/harshsingh2209/supply-chain-analysis
   Engine  : MySQL 8.0+
   Author  : Tran Thanh Hoa

   LƯU Ý VỀ TÊN CỘT
   -----------------
   Bảng `supply_chain_data` giữ NGUYÊN tên cột gốc từ file CSV Kaggle
   (có dấu cách, viết hoa chữ cái đầu, KHÔNG đổi thành snake_case).
   Vì tên cột có dấu cách nên mọi chỗ dùng đến đều phải bọc trong
   dấu backtick ` `, ví dụ: `Shipping costs`, `Defect rates`.
   Các cột TỰ TÍNH RA (aggregate/alias do mình đặt, không có trong
   dữ liệu gốc) thì vẫn đặt tên kiểu snake_case cho dễ đọc, ví dụ:
   total_cost, avg_defect_rate — đây KHÔNG phải cột gốc nên không
   cần giữ nguyên định dạng CSV.

   BỐI CẢNH KINH DOANH
   --------------------
   Đóng vai Supply Chain Analyst tại một tập đoàn FMCG. Chi phí vận
   chuyển đang tăng, bào mòn lợi nhuận — trong khi tỷ lệ hàng lỗi ở
   một số tuyến lại ảnh hưởng đến trải nghiệm khách hàng. Ban lãnh
   đạo chia 2 phe:
     (1) Tối ưu Chi phí     — muốn cắt giảm, chuyển sang Road/Rail
     (2) Chất lượng & Tốc độ — muốn giữ Air/Express để đảm bảo SLA

   CÁCH DÙNG: chạy Section 0 một lần để nạp dữ liệu, sau đó có thể
   chạy độc lập từng Q. Kết quả copy thẳng sang Excel/Power BI để
   vẽ biểu đồ trình bày cho sếp.
   ================================================================ */


/* ================================================================
   SECTION 0 — SETUP: Nạp dữ liệu thô (giữ nguyên tên cột gốc)
   ================================================================ */

DROP TABLE IF EXISTS supply_chain_data;

CREATE TABLE supply_chain_data (
    `Product type`             VARCHAR(50),
    `SKU`                       VARCHAR(20),
    `Price`                     DECIMAL(10,2),
    `Availability`              INT,
    `Number of products sold`  INT,
    `Revenue generated`         DECIMAL(14,2),
    `Customer demographics`    VARCHAR(50),
    `Stock levels`              INT,
    `Lead time`                 DECIMAL(10,2),
    `Order quantities`          INT,
    `Shipping times`            DECIMAL(10,2),
    `Shipping carriers`         VARCHAR(50),
    `Shipping costs`            DECIMAL(10,2),
    `Supplier name`             VARCHAR(50),
    `Location`                  VARCHAR(50),
    `Production volumes`        INT,
    `Manufacturing lead time`  DECIMAL(10,2),
    `Manufacturing costs`       DECIMAL(10,2),
    `Inspection results`        VARCHAR(20),
    `Defect rates`               DECIMAL(6,2),
    `Transportation modes`      VARCHAR(30),
    `Routes`                     VARCHAR(30),
    `Costs`                      DECIMAL(10,2)
) ENGINE=InnoDB;

-- Nạp CSV (đã import bằng Table Data Import Wizard hoặc LOAD DATA LOCAL INFILE)
-- Import Wizard sẽ tự map đúng cột vì tên cột trong CSV cũng có dấu cách y hệt
-- LOAD DATA LOCAL INFILE 'D:/path/to/supply_chain_data.csv'
-- INTO TABLE supply_chain_data
-- FIELDS TERMINATED BY ',' ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS;


/* ================================================================
   SECTION 1 — DATA QUALITY CHECK
   ================================================================ */

-- Q0.1: Tổng quan số dòng & giá trị thiếu ở các cột trọng yếu
SELECT
    COUNT(*)                                                          AS total_rows,
    SUM(CASE WHEN `Shipping costs` IS NULL THEN 1 ELSE 0 END)         AS missing_shipping_cost,
    SUM(CASE WHEN `Defect rates`   IS NULL THEN 1 ELSE 0 END)         AS missing_defect_rate,
    COUNT(DISTINCT `SKU`)                                              AS unique_skus,
    COUNT(DISTINCT `Shipping carriers`)                                AS unique_carriers,
    COUNT(DISTINCT `Transportation modes`)                             AS unique_modes
FROM supply_chain_data;

-- Q0.2: Phát hiện outliers bằng IQR (Interquartile Range) — cột Shipping costs
WITH quartiles AS (
    SELECT
        `Shipping costs`,
        NTILE(4) OVER (ORDER BY `Shipping costs`) AS quartile
    FROM supply_chain_data
),
q_bounds AS (
    SELECT
        MAX(CASE WHEN quartile = 1 THEN `Shipping costs` END) AS q1,
        MAX(CASE WHEN quartile = 3 THEN `Shipping costs` END) AS q3
    FROM quartiles
)
SELECT
    s.`SKU`, s.`Shipping costs`,
    ROUND(q3 - q1, 2)                       AS iqr,
    ROUND(q1 - 1.5 * (q3 - q1), 2)          AS lower_bound,
    ROUND(q3 + 1.5 * (q3 - q1), 2)          AS upper_bound
FROM supply_chain_data s
CROSS JOIN q_bounds
WHERE s.`Shipping costs` > q3 + 1.5 * (q3 - q1)
   OR s.`Shipping costs` < q1 - 1.5 * (q3 - q1);


/* ================================================================
   SECTION 2 — PHE "TỐI ƯU CHI PHÍ": Tiền đang chảy đi đâu?
   ================================================================ */

-- Q1: Cơ cấu chi phí vận chuyển theo Transportation Mode
SELECT
    `Transportation modes`,
    COUNT(*)                                            AS num_orders,
    ROUND(SUM(`Shipping costs`), 2)                     AS total_cost,
    ROUND(100.0 * SUM(`Shipping costs`) / SUM(SUM(`Shipping costs`)) OVER (), 2)
                                                          AS pct_of_total_cost,
    ROUND(AVG(`Shipping costs`), 2)                      AS avg_cost_per_order
FROM supply_chain_data
GROUP BY `Transportation modes`
ORDER BY total_cost DESC;

-- Q2: Xếp hạng nhà vận chuyển theo chi phí trung bình/đơn vị sản phẩm
SELECT
    `Shipping carriers`,
    ROUND(SUM(`Shipping costs`) / NULLIF(SUM(`Number of products sold`), 0), 2)
                                                          AS cost_per_unit,
    RANK() OVER (ORDER BY SUM(`Shipping costs`) / NULLIF(SUM(`Number of products sold`), 0) DESC)
                                                          AS rank_most_expensive,
    ROUND(AVG(AVG(`Shipping costs`)) OVER (), 2)         AS market_avg_cost
FROM supply_chain_data
GROUP BY `Shipping carriers`
ORDER BY cost_per_unit DESC;

-- Q3: Pareto Analysis — 20% SKU nào đang gây ra 80% chi phí vận chuyển?
WITH sku_cost AS (
    SELECT `SKU`, SUM(`Shipping costs`) AS total_cost
    FROM supply_chain_data
    GROUP BY `SKU`
),
ranked AS (
    SELECT
        `SKU`, total_cost,
        SUM(total_cost) OVER (ORDER BY total_cost DESC) AS running_total,
        SUM(total_cost) OVER ()                          AS grand_total,
        ROW_NUMBER() OVER (ORDER BY total_cost DESC)      AS rn,
        COUNT(*) OVER ()                                  AS total_skus
    FROM sku_cost
)
SELECT
    `SKU`, total_cost,
    ROUND(100.0 * running_total / grand_total, 2)         AS cumulative_cost_pct,
    ROUND(100.0 * rn / total_skus, 2)                      AS cumulative_sku_pct,
    CASE WHEN running_total / grand_total <= 0.8 THEN 'Vital Few (ưu tiên)' ELSE 'Trivial Many' END
                                                            AS pareto_group
FROM ranked
ORDER BY total_cost DESC;


/* ================================================================
   SECTION 3 — PHE "CHẤT LƯỢNG & TỐC ĐỘ": Rẻ có thực sự lợi?
   ================================================================ */

-- Q4: Tỷ lệ hàng lỗi theo Transportation Mode
SELECT
    `Transportation modes`,
    ROUND(AVG(`Defect rates`), 2)          AS avg_defect_rate,
    ROUND(AVG(`Shipping costs`), 2)        AS avg_shipping_cost,
    ROUND(AVG(`Shipping times`), 2)        AS avg_shipping_time_days
FROM supply_chain_data
GROUP BY `Transportation modes`
ORDER BY avg_defect_rate DESC;

-- Q5: Carrier nào vi phạm SLA nhiều nhất (thời gian giao > mục tiêu 3 ngày)?
SELECT
    `Shipping carriers`,
    COUNT(*)                                                          AS total_orders,
    SUM(CASE WHEN `Shipping times` > 3 THEN 1 ELSE 0 END)             AS orders_over_sla,
    ROUND(100.0 * SUM(CASE WHEN `Shipping times` > 3 THEN 1 ELSE 0 END) / COUNT(*), 2)
                                                                        AS pct_sla_breach
FROM supply_chain_data
GROUP BY `Shipping carriers`
ORDER BY pct_sla_breach DESC;

-- Q6: "Tiền nào của nấy" có đúng không? So sánh nhóm giá rẻ vs giá cao
WITH carrier_stats AS (
    SELECT
        `Shipping carriers`,
        ROUND(SUM(`Shipping costs`) / NULLIF(SUM(`Number of products sold`), 0), 2) AS cost_per_unit,
        ROUND(AVG(`Defect rates`), 2)                                                AS avg_defect_rate
    FROM supply_chain_data
    GROUP BY `Shipping carriers`
),
tiers AS (
    SELECT *,
        NTILE(2) OVER (ORDER BY cost_per_unit) AS price_tier   -- 1 = rẻ, 2 = đắt
    FROM carrier_stats
)
SELECT
    CASE WHEN price_tier = 1 THEN 'Nhóm giá rẻ' ELSE 'Nhóm giá cao' END AS price_group,
    ROUND(AVG(cost_per_unit), 2)   AS avg_cost_per_unit,
    ROUND(AVG(avg_defect_rate), 2) AS avg_defect_rate
FROM tiers
GROUP BY price_tier;


/* ================================================================
   SECTION 4 — KHUYẾN NGHỊ CÂN BẰNG (Combined Insight)
   ================================================================ */

-- Q7: Ma trận phân loại Carrier (Cost x Quality) — copy thẳng sang Power BI/Excel
SELECT
    `Shipping carriers`,
    ROUND(SUM(`Shipping costs`) / NULLIF(SUM(`Number of products sold`), 0), 2) AS cost_per_unit,
    ROUND(AVG(`Defect rates`), 2)                                                AS avg_defect_rate,
    ROUND(AVG(`Shipping times`), 2)                                              AS avg_shipping_time,
    CASE
        WHEN AVG(`Defect rates`) < 1.0
             AND SUM(`Shipping costs`) / NULLIF(SUM(`Number of products sold`), 0) < 5
            THEN '✅ Excellent — Giữ & mở rộng hợp đồng'
        WHEN AVG(`Defect rates`) > 3.0
            THEN '❌ Critical — Cần thay thế/đàm phán lại'
        WHEN AVG(`Defect rates`) < 1.5
             AND SUM(`Shipping costs`) / NULLIF(SUM(`Number of products sold`), 0) >= 5
            THEN '⚠️ Premium — Đắt nhưng chất lượng tốt, cân nhắc giữ cho hàng giá trị cao'
        ELSE '➖ Standard — Theo dõi thêm'
    END AS recommendation
FROM supply_chain_data
GROUP BY `Shipping carriers`
ORDER BY cost_per_unit;

-- Q8: Tóm tắt điều hành (Executive Summary) — 1 dòng duy nhất cho slide đầu tiên
SELECT
    ROUND(SUM(`Shipping costs`), 2)                                    AS total_shipping_cost,
    ROUND(AVG(`Defect rates`), 2)                                      AS overall_avg_defect_rate,
    (SELECT `Transportation modes` FROM supply_chain_data
        GROUP BY `Transportation modes`
        ORDER BY SUM(`Shipping costs`) DESC LIMIT 1)                   AS most_costly_mode,
    (SELECT `Shipping carriers` FROM supply_chain_data
        GROUP BY `Shipping carriers`
        ORDER BY AVG(`Defect rates`) DESC LIMIT 1)                     AS riskiest_carrier
FROM supply_chain_data;
