
/*

TÌNH HUỐNG VỀ VẤN ĐỀ DEADLOCK :
-MÔ TẢ TÌNH HUỐNG:
MỘT GIAO TÁC ĐANG THỰC HIỆN VIỆC THÊM 1 NHÂN VIÊN VÀ VIỆC ĐỌC 2 LẦN,GIỮ KHÓA ĐỌC ĐẾN CUỐI GIAO TÁC,GIAO TÁC 2
CŨNG ĐỌC 2 LẦN VÀ GIỮ KHÓA ĐẾN CUỐI GIAO TÁC.
GIAO TÁC 1 MUỐN THỰC HIỆN VIỆC INSERT TRÊN 1 ĐƠN VỊ DỮ LIỆU THÌ PHẢI ĐỢI GIAO TÁC 2 THỰC HIỆN VIỆC COMMIT THAO TÁC ĐỌC MỚI ĐƯỢC
INSERT,NHƯNG GIAO TÁC 2 CŨNG UPDATE NHÂN VIÊN VÀ PHẢI ĐỢI GIAO TÁC 1 COMMIT,DẪN ĐẾN VIỆC 2 GIAO TÁC ĐỢI NHAU VÀ DẪN ĐẾN DEADLOCK,
VÀ HỆ THỐNG TỰ ĐỘNG HỦY 1 GIAO TÁC ĐỂ GIAO TÁC KIA THỰC HIỆN TIẾP CÔNG VIỆC CỦA MÌNH
--> PHƯƠNG PHÁP GIẢI QUYẾT LÀ CHO THAO TÁC ĐỌC NHẢ RA NGAY MÀ KHÔNG PHẢI ĐỢI ĐẾN CUỐI NHƯNG VẤN ĐỀ SẼ BỊ LỖI TRANH CHÂP ĐỒNG THỜI
UNREPEATABLE READ.

*/

--T1
ALTER proc them_Nhanvien(@maNV nvarchar(10),@maCN nvarchar(3),@tenNV nvarchar(40),@SDT_NV nvarchar(12), @NgSinh date,@Luong money,@Tuoi int,@NQLNV nvarchar(10))
as 
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM NHANVIEN WITH (HOLDLOCK,ROWLOCK) WHERE MACHINHANH=@maCN
		if (@maNV is null or @maCN is null or @tenNV is null or @SDT_NV is null or @NgSinh is null or @Luong is null or @Tuoi is null )--or @NQLNV is null
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã chi nhánh có tồn tại
		if (not exists (select * from ChiNhanh where maChiNhanh=@maCN))
		begin
			print(N'Mã chi nhánh không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra nhân viên đã tồn tại
		if (exists (select * from NhanVien where maNV=@maNV))
		begin
			print(N'Mã nhân viên đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		WAITFOR DELAY N'00:00:05'
		insert into NhanVien 
		values (@maNV,@maCN,@tenNV,@SDT_NV,@NgSinh,@Luong,@Tuoi,@NQLNV)
		SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
exec them_Nhanvien NV011,NA1,N'NGUYỄN TRÍ TRUNG',0827609705,N'11/16/2019',190000.000,20,NULL

--T2
alter proc update_Nhanvien(@maNV nvarchar(10),@maCN nvarchar(3),@tenNV nvarchar(40),@SDT_NV nvarchar(12), @NgSinh date,@Luong money,@Tuoi int,@NQLNV nvarchar(10))
as 
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM NHANVIEN WITH (HOLDLOCK,ROWLOCK) WHERE MACHINHANH=@maCN
		if (@maNV is null or @maCN is null or @tenNV is null or @SDT_NV is null or @NgSinh is null or @Luong is null or @Tuoi is null )--or @NQLNV is null
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã chi nhánh có tồn tại
		if (not exists (select * from ChiNhanh where maChiNhanh=@maCN))
		begin
			print(N'Mã chi nhánh không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra nhân viên đã tồn tại
		if (NOT exists (select * from NhanVien where maNV=@maNV))
		begin
			print(N'Mã nhân viên không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra thông tin không được trùng lắp
		if (exists (select * from NhanVien where maNV=@maNV and maChiNhanh=@maCN and tenNV=@tenNV and soDT_NV=@SDT_NV and NgSinh=@NgSinh and Luong=@Luong and Tuoi=@Tuoi and maNguoiQLNV=@NQLNV))
		begin
			print(N'Thông tin trùng lắp')
			rollback transaction
			return
		end
		--sửa

		update NhanVien set maChiNhanh=@maCN, tenNV=@tenNV, soDT_NV=@SDT_NV, NgSinh=@NgSinh, Luong=@Luong, Tuoi=@Tuoi, maNguoiQLNV=@NQLNV where maNV=@maNV
		SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
exec update_Nhanvien NV001,NA1,N'NGUYỄN VĂN B',0827609705,N'11/16/2019',190000.000,20,NULL
-----------GIẢI QUYẾT VẤN ĐỀ
--CÓ THỂ HẠN CHẾ CÁC GIAO TÁC THỰC HIỆN VỚI CÙNG 1 ĐƠN VỊ DỮ LIỆU
--HẠN CHẾ MỨC CÔ LẬP(MỨC CÔ LẬP CÀNG CAO THÌ XỬ LÝ ĐỒNG THỜI CÀNG KÉM)
SET TRANSACTION ISOLATION LEVEL READ COMMITTED 
--BỎ ĐI NHỮNG CÀI ĐẶT TRÊN THAO TÁC