/*
XỬ LÝ VỀ VẤN ĐỀ UNREPEATABLE READ :
-MÔ TẢ TÌNH HUỐNG:
MỘT GIAO TÁC INSERT NHÂN VIÊN VÀO VÀ ĐỌC 2 LẦN ĐỂ KIẾM TRA XEM VIỆC INSERT ĐÓ CÓ THÀNH CÔNG
HAY KHÔNG.
VIỆC INSERT THÀNH CÔNG NHƯNG CÓ MỘT GIAO TÁC THỰC HIỆN VIỆC THAY ĐỔI TRÊN ĐƠN VỊ DỮ LIỆU
ĐÓ(UPDATE) VÀ LÀM CHO NGƯỜI THỰC HIỆN GIAO TÁC 1 MUỐN ĐỌC ĐƠN VỊ DỮ LIỆU CŨ KHÔNG ĐƯỢC(ĐƠN VỊ DỮ LIỆU CŨ LÚC NÀY ĐÃ UPDATE).
HƯỚNG GIẢI QUYẾT : TA CÓ THỂ GIỮ GIAO TÁC ĐỌC TỪ ĐẦU ĐẾN KHI COMMIT ĐỂ
TRÁNH CÓ GIAO TÁC KHÔNG THÊM GIỮA 2 LẦN ĐỌC CỦA GIAO TÁC 1.
*/
--T1
ALTER proc them_Nhanvien(@maNV nvarchar(10),@maCN nvarchar(3),@tenNV nvarchar(40),@SDT_NV nvarchar(12), @NgSinh date,@Luong money,@Tuoi int,@NQLNV nvarchar(10))
as 
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
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
exec them_Nhanvien NV0012,NA1,N'NGUYỄN VĂN A',0827609705,N'11/16/2019',190000.000,20,NULL

--T2
alter proc update_Nhanvien(@maNV nvarchar(10),@maCN nvarchar(3),@tenNV nvarchar(40),@SDT_NV nvarchar(12), @NgSinh date,@Luong money,@Tuoi int,@NQLNV nvarchar(10))
as 
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
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
exec update_Nhanvien NV001,NA1,N'NGUYỄN VĂN A',0827609705,N'11/16/2019',190000.000,20,NULL
-----GIẢI QUYẾT VẤN ĐỀ
--1.CÀI ĐĂT MỨC CÔ LẬP SỐ 3
--2.DÙNG KHÓA VÀ GIỮ THAO TÁC ĐỌC ĐẾN CUỐI GIAO TÁC
ALTER proc them_Nhanvien(@maNV nvarchar(10),@maCN nvarchar(3),@tenNV nvarchar(40),@SDT_NV nvarchar(12), @NgSinh date,@Luong money,@Tuoi int,@NQLNV nvarchar(10))
as 
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM NHANVIEN WITH(HOLDLOCK,ROWLOCK)WHERE MACHINHANH=@maCN
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