# Powerbi-supply-chain-analysis
Supply Chain Logistics Dashboard
Dashboard phân tích chuỗi cung ứng (Supply Chain Analytics) được xây dựng bằng Python (làm sạch, xử lý dữ liệu) và Power BI (mô hình hóa dữ liệu, DAX, trực quan hóa), nhằm lượng hóa sự đánh đổi giữa Chi phí – Tốc độ – Chất lượng trong hoạt động vận chuyển và hỗ trợ ra quyết định lựa chọn đối tác vận chuyển tối ưu.
Bối cảnh bài toán
Đóng vai Supply Chain Analyst tại một tập đoàn FMCG, dự án giải quyết bài toán: chi phí vận chuyển tăng cao đang bào mòn lợi nhuận, trong khi tỷ lệ hàng lỗi ở một số tuyến vận chuyển lại ảnh hưởng đến trải nghiệm khách hàng. Mục tiêu là khai thác dữ liệu vận chuyển để xác định tuyến/phương thức/nhà vận chuyển nào đang gây rủi ro, từ đó đề xuất phương án cân bằng giữa kiểm soát chi phí và đảm bảo chất lượng dịch vụ.
Nguồn dữ liệu
Supply Chain Analysis Dataset (Kaggle) — dữ liệu về sản phẩm, chi phí sản xuất/vận chuyển, thời gian giao hàng, tỷ lệ hàng lỗi, tuyến đường và nhà cung cấp.
Quy trình thực hiện
1. Xử lý dữ liệu bằng Python (ETL)
Nạp dữ liệu bằng Python script ngay trong Power BI (Pandas)
Chuẩn hóa tên cột, loại bỏ dòng thiếu dữ liệu quan trọng
Ép kiểu dữ liệu số, xử lý các giá trị lỗi định dạng
Phân loại Risk Level (High/Medium/Low) dựa trên Defect Rate
Tính Gross Profit từ Revenue, Shipping costs và Manufacturing costs
Xử lý outliers bằng kỹ thuật Winsorize cho các cột Shipping costs, Lead time, Shipping times
2. Mô hình hóa dữ liệu (Star Schema)
Tách dữ liệu phẳng thành mô hình Star Schema để tối ưu hiệu suất và cấu trúc phân tích đa chiều:
Fact_Orders — bảng sự kiện chứa các chỉ số đo lường
Dim_Product — thông tin sản phẩm (SKU, Product type, Price, Availability)
Dim_Logistics — thông tin vận chuyển (Carrier, Transportation mode, Route)
Dim_Supplier — thông tin nhà cung cấp (Supplier name, Location)
3. Tính toán chỉ số bằng DAX
Total Shipping Cost, Total Revenue
Avg Defect Rate
Shipping Cost Per Unit
Carrier Performance — phân loại nhà vận chuyển (Excellent / Standard / Critical) dựa trên chi phí và tỷ lệ lỗi
4. Xây dựng Dashboard trên Power BI
Dashboard gồm 10 visual trên 1 trang, tập trung vào phân tích trade-off chi phí – chất lượng:
Visual	Nội dung
Treemap	Tổng chi phí vận chuyển theo Transportation Mode
Line + Stacked Column Combo	Phân tích Pareto: Cumulative Shipping Cost % theo SKU (Top 20)
Line + Clustered Column Combo	So sánh Avg Defect Rate và Avg Shipping Cost theo Carrier
5x Card KPI	Total Revenue, Total Shipping Cost, Avg Defect Rate, Avg Shipping Cost, Avg Shipping Time
Ribbon Chart	Avg Shipping Cost theo Risk Level và Transportation Mode
Scatter Chart	Tương quan Avg Defect Rate – Avg Shipping Cost, kích thước theo Shipping Cost to Revenue Ratio, phân theo Carrier
Kết quả / Insight chính
Xác định các tuyến và nhà vận chuyển thuộc nhóm 20% gây ra phần lớn chi phí/rủi ro (theo nguyên lý Pareto 80/20)
Lượng hóa mối quan hệ giữa chi phí vận chuyển thấp và tỷ lệ hàng lỗi cao ở một số phương thức vận chuyển (Road/Rail)
Đề xuất phương án lựa chọn đối tác vận chuyển cân bằng giữa chi phí và chất lượng dịch vụ, thay vì chỉ tối ưu một chiều
Công cụ sử dụng
Python (Pandas) · Power BI · Power Query · DAX · Star Schema Modeling
File trong repo
supply-chain-logistics-dashboard.pbix — File Power BI chứa toàn bộ dashboard và mô hình dữ liệu
