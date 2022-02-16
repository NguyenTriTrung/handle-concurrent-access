/*
XỬ LÝ VỀ VẤN ĐỀ PHANTOM KHI THÊM 1 DỮ LIỆU:
VIỆC THÊM 1 DỮ LIỆU SẼ LÀM CHO VIỆC ĐỌC CỦA GIAO TÁC NHÂN VIÊN SẼ PHANTOM
DO GIAO TÁC UPDATE NHÂN VIÊN CÓ VIỆC ĐỌC 2 LẦN ĐỂ XEM NHÂN VIÊN ĐÓ CÓ ĐƯỢC UPDATE CHƯA
NHƯNG CÓ MỘT GIAO TÁC THÊM TRÊN 1 ĐƠN VỊ DỮ LIỆU CÙNG ĐIỀU KIỆN VỚI SELECT TRONG T2 
DẪN ĐẾN VIỆC ĐỌC THÊM 1 DÒNG DỮ LIỆU.2 LẦN ĐỌC CHO SỐ DÒNG TĂNG THÊM 1.
NÂNG MỨC CÔ LẬP LÊN SERIALIZABLE SẼ GIẢI QUYẾT ĐƯỢC VẤN ĐỀ DO CÓ KEY RANGE LOCK

*/
--T1
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
		WAITFOR DELAY N'00:00:05'
		update NhanVien set maChiNhanh=@maCN, tenNV=@tenNV, soDT_NV=@SDT_NV, NgSinh=@NgSinh, Luong=@Luong, Tuoi=@Tuoi, maNguoiQLNV=@NQLNV where maNV=@maNV
		SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
exec update_Nhanvien NV001,NA1,N'NGUYỄN TRÍ TRUNG',0827609705,N'11/16/2019',190000.000,20,NULL
--T2
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
		insert into NhanVien 
		values (@maNV,@maCN,@tenNV,@SDT_NV,@NgSinh,@Luong,@Tuoi,@NQLNV)
		SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
exec them_Nhanvien NV002,NA1,N'NGUYỄN TRÍ TRUNG',0827609705,N'11/16/2019',190000.000,20,NULL
---------------GIẢI QUYẾT VẤN ĐỀ LÀ ĐẶT MỨC CÔ LẬP THỨ 4
SET TRANSACTION ISOLATION LEVEL SERIALIZABLE
