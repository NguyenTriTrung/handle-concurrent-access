﻿/*
XỬ LÝ VỀ VẤN ĐỀ UNREPEATABLE READ :
-MÔ TẢ TÌNH HUỐNG:
MỘT GIAO TÁC INSERT KHÁCH HÀNG THÀNH VIÊN VÀO VÀ ĐỌC 2 LẦN ĐỂ KIẾM TRA XEM VIỆC INSERT ĐÓ CÓ THÀNH CÔNG
HAY KHÔNG.
VIỆC INSERT THÀNH CÔNG NHƯNG CÓ MỘT GIAO TÁC THỰC HIỆN VIỆC THAY ĐỔI TRÊN ĐƠN VỊ DỮ LIỆU
ĐÓ(UPDATE) VÀ LÀM CHO NGƯỜI THỰC HIỆN GIAO TÁC 1 MUỐN ĐỌC ĐƠN VỊ DỮ LIỆU CŨ KHÔNG ĐƯỢC(ĐƠN VỊ DỮ LIỆU CŨ LÚC NÀY ĐÃ UPDATE).
HƯỚNG GIẢI QUYẾT : TA CÓ THỂ GIỮ GIAO TÁC ĐỌC TỪ ĐẦU ĐẾN KHI COMMIT ĐỂ
TRÁNH CÓ GIAO TÁC KHÔNG THÊM GIỮA 2 LẦN ĐỌC CỦA GIAO TÁC 1.
*/
--T1
ALTER proc them_KH(@maKH nvarchar(10),@nvql nvarchar(10), @tenKH nvarchar(60), @sdt nvarchar(12))
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
		if( exists (select * from KhachHangThanhVien where maKH=@maKH))
		begin 
			print(N'Mã khách hàng đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		waitfor delay N'00:00:05'
		insert into KhachHangThanhVien 
		values (@maKH,@nvql,@tenKH,@sdt,0,N'Silver')
		select * from KHACHHANGTHANHVIEN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
EXEC them_KH N'KH005',N'NV001',N'NGUYỄN TRÍ TRUNG',0827609705


------

--T2
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
		update KhachHangThanhVien set maNQLThongTin=@nvql, tenKH=@tenKH, sdtKH=@sdt where maKH=@maKH
		select * from KHACHHANGTHANHVIEN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
EXEC update_thongtin_KH N'KH004',N'NV002',N'NGUYỄN THANH KIỀU',0827609705
------
--------GIẢI QUYẾT VẤN ĐỀ
--1. CÀI ĐẶT MỨC CÔ LẬP
--2. CÀI ĐẶT THẲNG VÔ THAO TÁC CỦA GIAO TÁC
ALTER proc them_KH(@maKH nvarchar(10),@nvql nvarchar(10), @tenKH nvarchar(60), @sdt nvarchar(12))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from KHACHHANGTHANHVIEN WITH(HOLDLOCK,ROWLOCK)
		if( @maKH is null  or @tenKH is null or @sdt is null)--or @nvql is null
		begin 
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã khách hàng có tồn tại
		if( exists (select * from KhachHangThanhVien where maKH=@maKH))
		begin 
			print(N'Mã khách hàng đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		waitfor delay N'00:00:05'
		insert into KhachHangThanhVien 
		values (@maKH,@nvql,@tenKH,@sdt,0,N'Silver')
		select * from KHACHHANGTHANHVIEN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go