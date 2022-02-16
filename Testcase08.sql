/*
Mô tả tình huống về phantom:
có một giao tác đang update và đọc 2 lần để xem trước và sau khi update 
nhưng lần thứ 2 đọc lại thêm 1 dữ liệu mới khác với ban đầu(thêm 1 dòng dữ liệu)
,đây là vấn đề phantom,chỉ được giải quyết nếu ta cài đặt mức cô lập thứ 4 là serializable
Giao tác T2 là giao tác thêm một đơn vị dữ liệu,ở đây ta đang làm việc
trên mức cô lập thứu 2 nên vấn đề đọc xong sẽ được nhả SL ngay,và chưa có key range lock.
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
EXEC update_thongtin_KH N'KH001',N'NV001',N'NGUYỄN TRÍ TRUNG',0827609705
------
--T2
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
		insert into KhachHangThanhVien 
		values (@maKH,@nvql,@tenKH,@sdt,0,N'Silver')
		select * from KHACHHANGTHANHVIEN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
EXEC them_KH N'KH002',N'NV001',N'NGUYỄN TRÍ TRUNG',0827609705

SELECT * FROM NHANVIEN

-----GIẢI QUYẾT VẤN ĐỀ
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE