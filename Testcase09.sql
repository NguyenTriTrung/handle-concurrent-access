/*
MÔ TẢ TÌNH HUỐNG PHANTOM MẤT MỘT DÒNG DỮ LIỆU:
KHI GIAO TÁC T1 THỰC HIỆN VIỆC UPDATE MỘT ĐƠN VỊ DỮ
LIỆU VÀ ĐỌC 2 LẦN ĐỂ XEM VIỆC UPDATE CÓ HIỆU QUẢ HAY KHÔNG NHƯNG 
SAU KHI ĐỌC 2 LẦN THÌ LẦN ĐỌC THỨ 2 CỦA GIAO TÁC THỨ NHẤT MẤT ĐI MỘT DÒNG DỮ LIÊU
NGUYÊN NHÂN LÀ DO GIỮA QUÁ TRÌNH ĐỌC 2 LẦN CÓ MỘT KHOẢNG BỊ DELAY VÀ VIỆC GIAO TÁC KHÁC SẼ
XÓA 1 NHÂN VIÊN VẤN ĐƯỢC THÌ Ở MỨC CÔ LẬP NÀY VIỆC ĐỌC
ĐƯỢC NHẢ NGAY CHỨU KHÔNG GIỮ ĐẾN CUỐI GIAO TÁC.
NHƯNG Ở ĐÂY VIỆC XỬ LÝ CHỈ CẦN LÀ MÌNH GIỮ VIỆC ĐỌC ĐẾN
CUỐI GIAO TÁC MÀ KHÔNG PHẢI NÂNG LÊN MỨC CÔ LẠP THỨ 4(TỨC LÀ CHỈ CẦN MỨC CÔ LẬP SỐ 3)
NHƯ VIỆC THÊM 1 DÒNG DỮ LIỆU.
*/
--T1
alter proc update_thongtin_KH(@maKH nvarchar(10),@nvql nvarchar(10), @tenKH nvarchar(60), @sdt nvarchar(12))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from KHACHHANGTHANHVIEN
		if( @maKH is null  or @tenKH is null or @sdt is null)--or @nvql is null
		begin 
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã khách hàng có tồn tại
		if(not exists (select * from KhachHangThanhVien where maKH=@maKH))
		begin 
			print(N'Mã khách hàng không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra thông tin trùng lắp
		if(exists (select * from KhachHangThanhVien where maKH=@maKH and maNQLThongTin=@nvql and tenKH=@tenKH and sdtKH=@sdt))
		begin 
			print(N'Thông tin trùng lắp')
			rollback transaction
			return
		end
		--sửa
		waitfor delay N'00:00:05'
		update KhachHangThanhVien set maNQLThongTin=@nvql, tenKH=@tenKH, sdtKH=@sdt where maKH=@maKH
		select * from KHACHHANGTHANHVIEN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
EXEC update_thongtin_KH N'KH001',N'NV002',N'NGUYỄN TRÍ TRUNG',0827609705

--T2
create proc xoa_KH (@maKH nvarchar(10))
as
Begin transaction
	Begin try		
		--Kiểm tra mã khách hàng có tồn tại
		select * from KHACHHANGTHANHVIEN
		if(not exists (select * from KhachHangThanhVien where maKH=@maKH))
		begin 
			print(N'Mã khách hàng không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra khách hàng còn Ưu đãi KHTV hay giỏ hàng không
		if(exists (select * from UuDaiKHTV where maKHTV=@maKH) or exists (select * from GioHang where maKH=@maKH))
		begin 
			print(N'Không thực hiện được thao tác xóa')
			rollback transaction
			return
		end
		--xóa
		delete from KhachHangThanhVien where maKH=@maKH
		select * from KHACHHANGTHANHVIEN
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go

exec xoa_KH N'KH001'

-----------------GIẢI QUYẾT VẤN ĐỀ
SET TRANSACTION ISOLATION LEVEL REPEATABLE READ 
alter proc update_thongtin_KH(@maKH nvarchar(10),@nvql nvarchar(10), @tenKH nvarchar(60), @sdt nvarchar(12))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from KHACHHANGTHANHVIEN WITH (HOLDLOCK,ROWLOCK)
		if( @maKH is null  or @tenKH is null or @sdt is null)--or @nvql is null
		begin 
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã khách hàng có tồn tại
		if(not exists (select * from KhachHangThanhVien where maKH=@maKH))
		begin 
			print(N'Mã khách hàng không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra thông tin trùng lắp
		if(exists (select * from KhachHangThanhVien where maKH=@maKH and maNQLThongTin=@nvql and tenKH=@tenKH and sdtKH=@sdt))
		begin 
			print(N'Thông tin trùng lắp')
			rollback transaction
			return
		end
		--sửa
		waitfor delay N'00:00:05'
		update KhachHangThanhVien set maNQLThongTin=@nvql, tenKH=@tenKH, sdtKH=@sdt where maKH=@maKH
		select * from KHACHHANGTHANHVIEN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
EXEC update_thongtin_KH N'KH001',N'NV002',N'NGUYỄN TRÍ TRUNG',0827609705