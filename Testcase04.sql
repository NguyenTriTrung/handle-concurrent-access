/*
+kHI TA SỬA THÔNG TIN MỘT NHÂN VIÊN THÌ SẼ XẢY RA VẤN ĐỀ NẾU CÓ 2 NGƯỜI CÙNG THỰC HIEEN
THAO TÁC SỬA THÌ THÔNG TIN CỦA GIAO TÁC COMMIT TRƯỚC SẼ BỊ THÔNG TIN CỦA
GIAO TÁC SAU ĐÈ LÊN.
+Ở ĐÂY GIẢ SỬ TA SỬA SỐ TIỀN CỦA NHÂN VIÊN NHƯNG CÓ MỘT NGƯỜI KHÁC CŨNG CÓ QUYỀN
SỬA SỐ TIỀN ĐÓ SẼ XẢY RA VẤN ĐỀ LÀ SỐ TIỀN CỦA GIAO TÁC ĐẦU SẼ MẤT ĐI.
+MẶC DÙ BAN ĐẦU CẢ 2 GIAO TÁC ĐIỀU ĐỌC CÙNG 1 DỮ LIỆU,NHƯNG CÁI CHÚNG TA 
MUỐN LÀ NẾU CÓ MỘT GIAO TÁC ĐANG THỰC HIÊN(UPDATE) TRÊN ĐƠN VỊ DỮ LIỆU NÀY THÌ GIAO TÁC 
KHÁC PHẢI ĐỢI VÀ KHÔNG ĐƯỢC ĐỌC TRÊN ĐƠN VỊ DỮ LIỆU ĐÓ ĐỂ ĐẾN KHI GIAO TÁC
1 UPDATE HOÀN TOÀN THÌ MỚI CÓ QUYỀN ĐỌC TRÊN ĐƠN VỊ DỮ LIỆU.
+TA SẼ DÙNG HOLDLOCK VÀ ROWLOCK Ở VIỆC ĐỌC TRƯỚC KHI UPDATE

*/

ALTER proc update_Nhanvien(@maNV nvarchar(10),@maCN nvarchar(3),@tenNV nvarchar(40),@SDT_NV nvarchar(12), @NgSinh date,@Luong money,@Tuoi int,@NQLNV nvarchar(10))
as 
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
			SELECT * FROM NHANVIEN  WHERE MACHINHANH=@maCN
		if (@maNV is null or @maCN is null or @tenNV is null or @SDT_NV is null or @NgSinh is null or @Luong is null or @Tuoi is null )
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
		if (not exists (select * from NhanVien where maNV=@maNV))
		begin
			print(N'Mã nhân viên không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra thông tin không được trùng lắp
		if (exists (select * from NhanVien where maNV=@maNV and maChiNhanh=@maCN and tenNV=@tenNV and soDT_NV=@SDT_NV and NgSinh=@NgSinh and Luong=@Luong and Tuoi=@Tuoi and maNguoiQLNV=@NQLNV))
		Begin
			print(N'Thông tin trùng lắp')
			rollback transaction
			return
		End
	End try
	Begin catch
		rollback transaction
	End catch
	--sửa
	WAITFOR DELAY '00:00:05'
	update NhanVien set maChiNhanh=@maCN, tenNV=@tenNV, soDT_NV=@SDT_NV, NgSinh=@NgSinh, Luong=@Luong, Tuoi=@Tuoi, maNguoiQLNV=@NQLNV where maNV=@maNV
	SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
Commit transaction
go
EXEC update_Nhanvien NV001,NA1,N'F',01232242222,'07-22-2001',2000000,20,NULL
--T2
EXEC update_Nhanvien 1,NA1,N'B',01232242222,'07-22-2001',2000000,19,NULL

--GIẢI QUYẾT VẤN ĐỀ LOSTUPDATE
ALTER proc update_Nhanvien(@maNV nvarchar(10),@maCN nvarchar(3),@tenNV nvarchar(40),@SDT_NV nvarchar(12), @NgSinh date,@Luong money,@Tuoi int,@NQLNV nvarchar(10))
as 
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
			SELECT * FROM NHANVIEN WITH (HOLDLOCK,ROWLOCK)  WHERE MACHINHANH=@maCN
		if (@maNV is null or @maCN is null or @tenNV is null or @SDT_NV is null or @NgSinh is null or @Luong is null or @Tuoi is null )
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
		if (not exists (select * from NhanVien where maNV=@maNV))
		begin
			print(N'Mã nhân viên không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra thông tin không được trùng lắp
		if (exists (select * from NhanVien where maNV=@maNV and maChiNhanh=@maCN and tenNV=@tenNV and soDT_NV=@SDT_NV and NgSinh=@NgSinh and Luong=@Luong and Tuoi=@Tuoi and maNguoiQLNV=@NQLNV))
		Begin
			print(N'Thông tin trùng lắp')
			rollback transaction
			return
		End
	End try
	Begin catch
		rollback transaction
	End catch
	--sửa
	WAITFOR DELAY '00:00:05'
	update NhanVien set maChiNhanh=@maCN, tenNV=@tenNV, soDT_NV=@SDT_NV, NgSinh=@NgSinh, Luong=@Luong, Tuoi=@Tuoi, maNguoiQLNV=@NQLNV where maNV=@maNV
	SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
Commit transaction
go