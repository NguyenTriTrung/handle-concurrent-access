/*
MÔ TẢ TÍNH HUỐNG DIRTY READ TRONG XỬ LÝ ĐỒNG THỜI:
-KHI THÊM MỘT CHI TIẾT HÓA ĐƠN NHƯNG BỊ WAITFOR DELAY DẪN ĐẾN CHƯA CẬP NHẬT ĐƯỢC SỐ TIỀN
Ở TỔNG HÓA ĐƠN DẪN ĐẾN ĐỌC DỮ LIỆU BỊ SAI NẾU CÓ NGƯỜI ĐỌC HÓA ĐƠN VÀ CHI TIẾT TỪNG 
MÓN ĂN Ở HÓA ĐƠN
-GIẢ QUYẾT TÍNH HUỐNG CÓ THỂ LÀ CÀI ĐẶT TRỰC TIẾP Ở HÀM HOẶC NÂNG MỨC CÔ LẬP ĐỂ CÓ SL

*/

ALTER proc them_chitietHD (@maHD nvarchar(11), @machitietHD nvarchar(11), @mamon nvarchar(10), @sophan int)
as
Begin transaction
	--xác định ngày lập hóa đơn
	SELECT * FROM ChiTietHD WHERE maHD=@maHD
	declare @ngayHD date
	set @ngayHD = (select ngaylapHD from HoaDon where maHD=@maHD)
	--Xác định mã chi nhánh 
	declare @maCN nvarchar(3)
	set @maCN = (select maChiNhanh from HoaDon where maHD=@maHD)
	Begin try
		--Kiểm tra thông tin không được rỗng
		if( @maHD is null or @machitietHD is null or @mamon is null or @sophan is null )
		begin 
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã hóa đơn có tồn tại
		if(not exists (select * from HoaDon where maHD=@maHD))
		begin 
			print(N'Mã hóa đơn không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra mã món có tồn tại
		if(not exists (select * from Mon where mamon=@mamon))
		begin 
			print(N'Mã món không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra món ăn đã có trong hóa đơn
		if( exists (select * from ChiTietHD where maHD=@maHD and mamon=@mamon))
		begin 
			print(N'Món ăn đã có trong hóa đơn')
			rollback transaction
			return
		end
		--Kiểm tra số lượng trong menu còn đủ
		if (exists(select * from ChiTietMenu where mamon=@mamon and machinhanh=@maCN and datemenu=@ngayHD and sophanconlai<@sophan))
		begin
			print(N'Số lượng món còn lại không đủ')
			rollback transaction
			return
		end
		--Kiểm tra hóa đơn đã xử lý
		if (exists (select * from HoaDon where maHD=@maHD and matrangthaihd=0)) -- mã trạng thái = 0 <=> chưa xử lý
		begin
			print(N'Hóa đơn đã được xử lý không thể thay đổi')
			rollback transaction
			return
		end
		--Tính tổng tiền
		declare @tongtien money
		set @tongtien = (select gia from Mon where mamon=@mamon)*@sophan
		--Thêm
		insert into ChiTietHD 
		values(@maHD,@maCN,@machitietHD,@mamon,@sophan,@tongtien,@ngayHD)
		--Cập nhật hóa đơn
		WAITFOR DELAY '00:00:05'
		exec update_tongHD @mahd, @tongtien,1
		--Cập nhật chi tiết menu
		update ChiTietMenu set sophanconlai=sophanconlai-@sophan where mamon=@mamon and machinhanh=@maCN and datemenu=@ngayHD
		SELECT * FROM ChiTietHD WHERE maHD=@maHD
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
EXEC them_chitietHD 'HD015','CTHD036','M003',2


CREATE PROC CHITIETTUNGHOADON
AS
BEGIN
	SELECT * FROM HOADON join CHITIETHD on HOADON.MAHD=CHITIETHD.MAHD
END
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
EXEC CHITIETTUNGHOADON

----GIẢI QUYẾT LÀ NÂNG MỨC CÔ LẬP LÊN SỐ 2 hay cài đặt thẳng vào hàm đọc để giữu đến cuối giao tác
