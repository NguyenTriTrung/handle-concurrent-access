/*
TÌNH HUỐNG VỀ VẤN ĐỀ DEADLOCK :
-MÔ TẢ TÌNH HUỐNG:
MỘT GIAO TÁC ĐANG THỰC HIỆN VIỆC THÊM 1 KHÁCH HÀNG VÀ VIỆC ĐỌC 2 LẦN,GIỮ KHÓA ĐỌC ĐẾN CUỐI GIAO TÁC,GIAO TÁC 2
CŨNG ĐỌC 2 LẦN VÀ GIỮ KHÓA ĐẾN CUỐI GIAO TÁC.
GIAO TÁC 1 MUỐN THỰC HIỆN VIỆC INSERT TRÊN 1 ĐƠN VỊ DỮ LIỆU THÌ PHẢI ĐỢI GIAO TÁC 2 THỰC HIỆN VIỆC COMMIT THAO TÁC ĐỌC MỚI ĐƯỢC
INSERT,NHƯNG GIAO TÁC 2 CŨNG UPDATE KHÁCH HÀNG VÀ PHẢI ĐỢI GIAO TÁC 1 COMMIT,DẪN ĐẾN VIỆC 2 GIAO TÁC ĐỢI NHAU VÀ DẪN ĐẾN DEADLOCK,
VÀ HỆ THỐNG TỰ ĐỘNG HỦY 1 GIAO TÁC ĐỂ GIAO TÁC KIA THỰC HIỆN TIẾP CÔNG VIỆC CỦA MÌNH
--> PHƯƠNG PHÁP GIẢI QUYẾT LÀ CHO THAO TÁC ĐỌC NHẢ RA NGAY MÀ KHÔNG PHẢI ĐỢI ĐẾN CUỐI NHƯNG VẤN ĐỀ SẼ BỊ LỖI TRANH CHÂP ĐỒNG THỜI
UNREPEATABLE READ.
*/
--T1

ALTER proc them_KH(@maKH nvarchar(10),@nvql nvarchar(10), @tenKH nvarchar(60), @sdt nvarchar(12))
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
		waitfor delay N'00:00:05'
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
EXEC them_KH N'KH006',N'NV001',N'NGUYỄN TRÍ TRUNG',0827609705

SELECT * FROM NHANVIEN
------


--T2
alter proc update_thongtin_KH(@maKH nvarchar(10),@nvql nvarchar(10), @tenKH nvarchar(60), @sdt nvarchar(12))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from KHACHHANGTHANHVIENWITH WITH (HOLDLOCK,ROWLOCK)
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
EXEC update_thongtin_KH N'KH004',N'NV002',N'NGUYỄN TRÍ TRUNG',0827609705
------
-----------GIẢI QUYẾT VẤN ĐỀ
--CÓ THỂ HẠN CHẾ CÁC GIAO TÁC THỰC HIỆN VỚI CÙNG 1 ĐƠN VỊ DỮ LIỆU
--HẠN CHẾ MỨC CÔ LẬP(MỨC CÔ LẬP CÀNG CAO THÌ XỬ LÝ ĐỒNG THỜI CÀNG KÉM)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
--BỎ ĐI NHỮNG CÀI ĐẶT TRÊN THAO TÁC