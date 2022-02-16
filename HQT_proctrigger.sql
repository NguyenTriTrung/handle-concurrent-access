--													LOẠI
--	Thêm
create proc Them_Loai (@maloai nvarchar(3), @tenloai nvarchar(40))
as
Begin transaction
	Begin try
		--kiểm tra thông tin không được rỗng
		SELECT * FROM Loai with (holdlock,rowlock)
		if ( @maloai is null or @tenloai is null)
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--kiểm tra mã loại có tồn tại
		if (exists (select * from Loai where maLoai=@maloai))
		begin
			print(N'Mã loại đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		insert into Loai 
		values (@maloai,@tenloai,0)
		SELECT * FROM Loai 
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
exec Them_Loai 'N01',N'BÁNH XÈO'
----XEM SỐ LƯỢNG TỪNG MÓN THUỘC LOẠI
CREATE PROC CHITIETLOAI
AS
BEGIN
	SELECT * FROM LOAI join Mon on LOAI.MALOAI=Mon.MALOAI
END

--	Cập nhật

create proc Update_Loai (@maloai nvarchar(3), @tenloai nvarchar(40))
as
Begin transaction
	Begin try
		--kiểm tra thông tin không được rỗng
		SELECT * FROM Loai with (holdlock,rowlock)
		if ( @maloai is null or @tenloai is null)
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--kiểm tra mã loại có tồn tại
		if (not exists (select * from Loai where maLoai=@maloai))
		begin
			print(N'Mã loại không tồn tại')
			rollback transaction
			return
		end
		--kiểm tra thông tin trùng khớp
		if (exists (select * from Loai where maLoai=@maloai and tenloai=@tenloai))
		begin
			print(N'Thông tin trùng khớp')
			rollback transaction
			return
		end
		--Update
		update Loai set tenloai=@tenloai where maLoai=@maloai
		SELECT * FROM Loai 
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--	Xóa
create trigger Xoa_loai on Loai
for delete
as
Begin
	if (exists (select * from deleted where tongsomon > 0))
	Begin
		raiserror(N'Không được phép xóa',16,1)
		rollback tran
	End
End
go
--													MÓN
--	Thêm
create proc Them_Mon (@mamon nvarchar(10),@tenmon nvarchar(40),@maloai nvarchar(3),@gia money,@gioithieu nvarchar(200))
as
Begin transaction
	Begin try
		--kiểm tra thông tin không được rỗng
		SELECT * FROM Mon 
		if ( @mamon is null or @tenmon is null or  @maloai is null or @gia is null or @gioithieu is null)
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--kiểm tra mã món có tồn tại
		if (exists (select * from Mon where maMon=@mamon))
		begin
			print(N'Mã món không tồn tại')
			rollback transaction
			return
		end
		--kiểm tra mã loại có tồn tại
		if (not exists (select * from Loai where maLoai=@maloai))
		begin
			print(N'Mã loại không tồn tại')
			rollback transaction
			return
		end
			insert into Mon
			values (@mamon,@tenmon,@maloai,@gia,@gioithieu)
			declare @tongsomon int
			set @tongsomon=(SELECT* FROM Loai where maLoai=@maloai)
			--Tăng số lượng món ở loại
			update Loai set tongsomon = @tongsomon + 1 where maLoai=@maloai
			SELECT * FROM Mon 
	End try
	Begin catch
		rollback transaction
	End catch
	--Thêm
Commit transaction
go
--
ALTER proc Update_Mon (@mamon nvarchar(10),@tenmon nvarchar(40),@maloai nvarchar(3),@gia money,@gioithieu nvarchar(200))
as
Begin transaction
	Begin try
		--kiểm tra thông tin không được rỗng
		select * from Mon where maMon=@mamon
		if ( @mamon is null or @tenmon is null or  @maloai is null or @gia is null or @gioithieu is null)
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--kiểm tra mã món có tồn tại
		if (NOT exists (select * from Mon where maMon=@mamon))
		begin
			print(N'Mã món KHÔNG tồn tại')
			rollback transaction
			return
		end
		--kiểm tra mã loại có tồn tại
		if (not exists (select * from Loai where maLoai=@maloai))
		begin
			print(N'Mã loại không tồn tại')
			rollback transaction
			return
		end
		--kiểm tra thông tin trùng khớp
		if (exists (select * from Mon where maMon=@mamon and tenMon=@tenmon and maLoai=@maloai and Gia=@gia and GioiThieu=@gioithieu))
		begin
			print(N'Thông tin trùng khớp')
			rollback transaction
			return
		end
	declare @sl money 
	declare @maloaibandau nvarchar(10)
	set @sl=(select TONGSOMON from LOAI join Mon on LOAI.MALOAI=Mon.MALOAI where MAMON=@mamon)
	set @maloaibandau=(select MALOAI from  MON where MAMON=@mamon)
	update LOAI set TONGSOMON=TONGSOMON+1 WHERE MALOAI= @maloai
	update LOAI set TONGSOMON=@sl-1 WHERE MALOAI= @maloaibandau
	update Mon set tenMon=@tenmon, maLoai=@maloai, Gia=@gia, GioiThieu=@gioithieu where MAMON=@mamon
	select * from Mon where maMon=@mamon
	--nếu đổi mã loại thì phải update lại số lượng món trong loại
	End try
	Begin catch
		PRINT N'LỖI'
		rollback transaction
	End catch
	--update
Commit transaction
go
--	Xoa
alter proc Xoa_mon(@mamon nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra món có tồn tại
		select * from Mon where maMon=@mamon
		if (not exists( select * from Mon where maMon=@mamon))
		begin
			print(N'Mã món không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra món có tồn tại trong menu
		if (exists (select * from ChiTietMenu where maMon=@mamon))
		begin
			print(N'Không được phép xóa')
			rollback transaction
			return
		end
		--Kiểm tra món đã được đặt 
	declare @maloaibandau nvarchar(10)
	set @maloaibandau=(select MALOAI from Mon where maMon=@mamon)
	delete from Mon where maMon=@mamon
	update LOAI SET TONGSOMON=TONGSOMON-1 WHERE MALOAI=@maloaibandau
	select * from Mon where maMon=@mamon
	End try
	Begin catch
		rollback transaction
	End catch
	--xóa và cập nhật lại số lượng của loại

Commit transaction
go
--													CHI NHÁNH
-- Thêm
create proc them_ChiNhanh(@maCN nvarchar(3),@tenCN nvarchar(40),@quan nvarchar(15), @phuong nvarchar(15), @diachichitiet nvarchar(50),@DTCN nvarchar(12),@nvql nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM ChiNhanh
		if (@maCN is null or @tenCN is null or @diachichitiet is null or @DTCN is null or @nvql is null or @quan is null or @phuong is null)
		begin
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã chi nhánh có tồn tại
		if ( exists (select * from ChiNhanh where maChiNhanh=@maCN))
		begin
			print(N'Mã chi nhánh đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		insert into ChiNhanh 
		values (@maCN,@tenCN,@quan,@phuong,@diachichitiet,@DTCN,@nvql)
		SELECT * FROM ChiNhanh
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
--	Update
create proc update_ChiNhanh(@maCN nvarchar(3),@tenCN nvarchar(40),@quan nvarchar(15), @phuong nvarchar(15), @diachichitiet nvarchar(50),@DTCN nvarchar(12),@nvql nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM ChiNhanh
		if (@maCN is null or @tenCN is null or @diachichitiet is null or @DTCN is null or @nvql is null or @quan is null or @phuong is null)
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
		--Kiểm tra thông tin có trùng khớp
		if (exists (select * from ChiNhanh where maChiNhanh=@maCN and tenChiNhanh=@tenCN and Quan=@quan and Phuong=@phuong and DiaChiChiTiet=@diachichitiet and DienThoaiChiNhanh=@DTCN and maNguoiQLChiNhanh=@nvql))
		begin
			print(N'Thông tin trùng khớp')
			rollback transaction
			return
		end
		--update
		update ChiNhanh set tenChiNhanh=@tenCN, Quan=@quan, Phuong=@phuong, DienThoaiChiNhanh=@DTCN, maNguoiQLChiNhanh=@nvql where maChiNhanh=@maCN
		SELECT * FROM ChiNhanh
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--													MENU
--Thêm
create proc them_Menu (@maCN nvarchar(3), @ghichumenu nvarchar(200), @mamenu int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WHERE maChiNhanh=@maCN
		if (@maCN is null or @ghichumenu is null or @mamenu is null)
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
		--Kiểm tra menu đã tồn tại
		if (exists (select * from Menu where maChiNhanh=@maCN and maMenu=@mamenu))
		begin
			print(N'Menu đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		insert into Menu 
		values (@maCN,@ghichumenu,@mamenu)
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
-- sửa

create proc update_Menu (@maCN nvarchar(3), @ghichumenu nvarchar(200), @mamenu int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WHERE maChiNhanh=@maCN
		if (@maCN is null or @ghichumenu is null or @mamenu is null)
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
		--Kiểm tra menu đã tồn tại
		if (not exists (select * from Menu where maChiNhanh=@maCN and maMenu=@mamenu))
		begin
			print(N'Menu không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra thông tin không được trùng khớp
		if (not exists (select * from Menu where maChiNhanh=@maCN and GhiChuMenu=@ghichumenu and maMenu=@mamenu))
		begin
			print(N'Thông tin bị trùng khớp')
			rollback transaction
			return
		end
		--thêm
		update Menu set GhiChuMenu=@ghichumenu where maChiNhanh=@maCN and maMenu=@mamenu
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
--	Xóa
create proc xoa_Menu (@maCN nvarchar(3),@mamenu int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WHERE maChiNhanh=@maCN
		if (@maCN is null or @mamenu is null)
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
		--Kiểm tra menu đã tồn tại
		if (not exists (select * from Menu where maChiNhanh=@maCN and maMenu=@mamenu))
		begin
			print(N'Menu không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra chi tiết menu
		if (exists (select * from ChiTietMenu where MaChiNhanh=@maCN and maMenu=@mamenu))
		begin
			print(N'Không thể xóa khi chi tiết còn tồn tại')
			rollback transaction
			return
		end
		--xóa
		delete Menu where maChiNhanh=@maCN and maMenu=@mamenu
		select * from Menu WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go

--									ChiTietMenu
--	Thêm
create proc Them_chitietmenu (@maCN nvarchar(3),@mamenu int,@date date,@mamon nvarchar(10),@tongsophan int,@phanconlai int,@ghichu nvarchar(200))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WHERE maChiNhanh=@maCN AND maMenu=@mamenu
		if (@maCN is null or @mamenu is null or @date is null or @mamon is null or @tongsophan is null or @phanconlai is null or @ghichu is null)
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
		--Kiểm tra món ăn có tồn tại
		if (exists (select * from Mon where maMon=@mamon))
		begin
			print(N'Mã món không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra chi tiết menu đã tồn tại
		if (exists (select * from ChiTietMenu where maChiNhanh=@maCN and maMenu=@mamenu and maMon=@mamon))
		begin
			print(N'ChiTietMenu đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		insert into ChiTietMenu
		values (@maCN,@mamenu,@date,@mamon,@tongsophan,@phanconlai,@ghichu)
		select * from Menu WHERE maChiNhanh=@maCN AND maMenu=@mamenu
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--	Sửa
create proc Update_chitietmenu (@maCN nvarchar(3),@mamenu int,@date date,@mamon nvarchar(10),@tongsophan int,@phanconlai int,@ghichu nvarchar(200))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WHERE maChiNhanh=@maCN AND maMenu=@mamenu
		if (@maCN is null or @mamenu is null or @date is null or @mamon is null or @tongsophan is null or @phanconlai is null or @ghichu is null)
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
		--Kiểm tra món ăn có tồn tại
		if (exists (select * from Mon where maMon=@mamon))
		begin
			print(N'Mã món không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra chi tiết menu đã tồn tại
		if (not exists (select * from ChiTietMenu where maChiNhanh=@maCN and maMenu=@mamenu and maMon=@mamon))
		begin
			print(N'ChiTietMenu không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra thông tin không được trùng lắp
		if (exists (select * from ChiTietMenu where maChiNhanh=@maCN and maMenu=@mamenu and DateMenu=@date and maMon=@mamon and tongsophan=@tongsophan and sophanconlai=@phanconlai and GhichuChitiet=@ghichu))
		begin
			print(N'Thông tin trùng lắp')
			rollback transaction
			return
		end
		--update
		update ChiTietMenu set DateMenu=@date , tongsophan=@tongsophan, sophanconlai=@phanconlai,GhichuChitiet=@ghichu 
		where MaChiNhanh=@maCN and maMenu=@mamenu and maMon=@mamon
		select * from Menu WHERE maChiNhanh=@maCN AND maMenu=@mamenu
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
-- Tìm kiếm Menu theo ngày và chi nhánh
create proc Tim_Menu (@macn nvarchar(3), @date date)
as
Begin transaction
	Begin try
		--Kiểm tra chi nhánh có tồn tại
		if(not exists (select * from ChiNhanh where maChiNhanh=@macn))
		begin
			print(N'Mã chi nhánh không tồn tại')
			rollback transaction
		end
		--Xuất thông tin menu theo ngày của chi nhánh
		select * from ChiTietMenu where MaChiNhanh=@macn and DateMenu=@date
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
-- Xóa 
create proc Xoa_chitietmenu (@maCN nvarchar(3),@mamenu int,@mamon nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from Menu WHERE maChiNhanh=@maCN AND maMenu=@mamenu
		if (@maCN is null or @mamenu is null or @mamon is null)
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
		--Kiểm tra món ăn có tồn tại
		if (exists (select * from Mon where maMon=@mamon))
		begin
			print(N'Mã món không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra chi tiết menu đã tồn tại
		if (exists (select * from ChiTietMenu where maChiNhanh=@maCN and maMenu=@mamenu and maMon=@mamon))
		begin
			print(N'ChiTietMenu đã tồn tại')
			rollback transaction
			return
		end
		--xóa
		delete from ChiTietMenu where MaChiNhanh=@maCN and maMenu=@mamenu and maMon=@mamon
		select * from Menu WHERE maChiNhanh=@maCN AND maMenu=@mamenu
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go

--												NHÂN VIÊN
--	Thêm
create proc them_Nhanvien(@maNV nvarchar(10),@maCN nvarchar(3),@tenNV nvarchar(40),@SDT_NV nvarchar(12), @NgSinh date,@Luong money,@Tuoi int,@NQLNV nvarchar(10))
as 
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
		if (@maNV is null or @maCN is null or @tenNV is null or @SDT_NV is null or @NgSinh is null or @Luong is null or @Tuoi is null or @NQLNV is null)
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

ALTER PROC THONGKESONHANVIENTHUOCCHINHANH
AS
BEGIN
	SELECT CHINHANH.MACHINHANH, COUNT(NHANVIEN.MANV) AS SONHANVIEN
	FROM CHINHANH JOIN NHANVIEN ON CHINHANH.MACHINHANH=NHANVIEN.MACHINHANH
	GROUP BY CHINHANH.MACHINHANH
END
--Sửa
create proc update_Nhanvien(@maNV nvarchar(10),@maCN nvarchar(3),@tenNV nvarchar(40),@SDT_NV nvarchar(12), @NgSinh date,@Luong money,@Tuoi int,@NQLNV nvarchar(10))
as 
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM NHANVIEN WHERE MACHINHANH=@maCN
		if (@maNV is null or @maCN is null or @tenNV is null or @SDT_NV is null or @NgSinh is null or @Luong is null or @Tuoi is null or @NQLNV is null)
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
--Tìm kiếm nhân viên theo mã cn
create proc tim_Nhanvien_maCN (@macn nvarchar(3))
as
Begin transaction
	Begin try
		--Kiểm tra mã chi nhánh có tồn tại
		if (not exists (select * from ChiNhanh where maChiNhanh=@maCN))
		begin
			print(N'Mã chi nhánh không tồn tại')
			rollback transaction
			return
		end
		--tìm
		select * from NhanVien where maChiNhanh=@macn
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
--Tìm thông tin nhân viên theo mã
create proc tim_Nhanvien_maNV (@maNV nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra mã nhân viên có tồn tại
		if (not exists (select * from NhanVien where maNV=@maNV))
		begin
			print(N'Mã nhân viên không tồn tại')
			rollback transaction
			return
		end
		--tìm
		select * from NhanVien where maNV=@maNV
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--												KHÁCH HÀNG
--Thêm
Create proc them_KH(@maKH nvarchar(10),@nvql nvarchar(10), @tenKH nvarchar(60), @sdt nvarchar(12))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from KHACHHANGTHANHVIEN
		if( @maKH is null or @nvql is null or @tenKH is null or @sdt is null)
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
--sửa thông tin
Create proc update_thongtin_KH(@maKH nvarchar(10),@nvql nvarchar(10), @tenKH nvarchar(60), @sdt nvarchar(12))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		select * from KHACHHANGTHANHVIEN
		if( @maKH is null or @nvql is null or @tenKH is null or @sdt is null)
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
--cập nhật điểm và hạng
create proc capnhat_KH(@maKH nvarchar(10),@diem int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		if( @maKH is null or @diem is null)
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
		--cập nhật
		declare @temp int
		set @temp = (select Diemtichluy from KhachHangThanhVien where maKH=@maKH) + @diem
		if ( @temp < 5000000)
			update KhachHangThanhVien set Diemtichluy= @temp where maKH=maKH
		if (@temp >= 5000000 and @temp < 20000000)
			update KhachHangThanhVien set Diemtichluy= @temp, Hang=N'Gold' where maKH=maKH
		if (@temp >= 20000000)
			update KhachHangThanhVien set Diemtichluy= @temp, Hang=N'Diamond' where maKH=maKH
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
--xóa
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

--												ƯU ĐÃI KHTV
--	Thêm 
create proc them_UudaiKH (@magiamgia int,@maKH nvarchar(10),@tenmagg nvarchar(40),@tiengiam money)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
		if( @maKH is null or @magiamgia is null or @tenmagg is null or @tiengiam is null)
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
		-- Kiểm tra ưu đãi có tồn tại
		if(exists (select * from UuDaiKHTV where maKHTV=@maKH and maGiamGiaKH=@magiamgia))
		begin 
			print(N'Mã ưu đãi đã tồn tại')
			rollback transaction
			return
		end
		--thêm
		insert into UuDaiKHTV 
		values (@magiamgia,@maKH,@tenmagg,@tiengiam)
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--	sửa
create proc update_UudaiKH (@magiamgia int,@maKH nvarchar(10),@tenmagg nvarchar(40),@tiengiam money)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
		if( @maKH is null or @magiamgia is null or @tenmagg is null or @tiengiam is null)
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
		-- Kiểm tra ưu đãi có tồn tại
		if(not exists (select * from UuDaiKHTV where maKHTV=@maKH and maGiamGiaKH=@magiamgia))
		begin 
			print(N'Mã ưu đãi không tồn tại')
			rollback transaction
			return
		end
		-- Kiểm tra thông tin trùng lắp
		if(exists (select * from UuDaiKHTV where maKHTV=@maKH and maGiamGiaKH=@magiamgia and tenmaGiamGiaKH=@tenmagg and sotiengiamTV=@tiengiam))
		begin 
			print(N'Thông tin bị trùng lắp')
			rollback transaction
			return
		end
		--sửa
		update UuDaiKHTV set tenmaGiamGiaKH=@tenmagg, sotiengiamTV=@tiengiam where maKHTV=@maKH and maGiamGiaKH=@magiamgia
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
--	Xóa
create proc xoa_UudaiKH (@magiamgia int,@maKH nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
		if( @maKH is null or @magiamgia is null)
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
		-- Kiểm tra ưu đãi có tồn tại
		if(not exists (select * from UuDaiKHTV where maKHTV=@maKH and maGiamGiaKH=@magiamgia))
		begin 
			print(N'Mã ưu đãi không tồn tại')
			rollback transaction
			return
		end
		--xóa
		delete from UuDaiKHTV where maKHTV=@maKH and maGiamGiaKH=@magiamgia
		SELECT * FROM UuDaiKHTV WHERE maKHTV=@maKH
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go

--											GIỎ HÀNG
--	Thêm
create proc them_giohang(@maKH nvarchar(10),@maHD nvarchar(11),@matrangthai int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM GioHang WHERE maKHTV=@maKH
		if( @maKH is null or @maHD is null or @matrangthai is null)
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
		--Kiểm tra mã khách hàng có tồn tại
		if(not exists (select * from KhachHangThanhVien where maKH=@maKH))
		begin 
			print(N'Mã khách hàng không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra khách hàng đã có giỏ hàng
		if(exists (select * from GioHang where maKH=@maKH))
		begin 
			print(N'Khách hàng đã có giỏ hàng')
			rollback transaction
			return
		end
		--thêm
		insert into GioHang
		values (@maHD,@maKH,@matrangthai)
		SELECT * FROM GioHang WHERE maKHTV=@maKH
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--	 Sửa
create proc update_giohang(@maKH nvarchar(10),@maHD nvarchar(11),@matrangthai int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM GioHang WHERE maKH=@maKH
		if( @maKH is null or @maHD is null or @matrangthai is null)
		begin 
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã order có tồn tại
		if(not exists (select * from HoaDon where maHD=@maHD))
		begin 
			print(N'Mã order không tồn tại')
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
		--Kiểm tra khách hàng đã có giỏ hàng
		if(not exists (select * from GioHang where maKH=@maKH))
		begin 
			print(N'Khách hàng không có giỏ hàng')
			rollback transaction
			return
		end
		--Kiểm tra thông tin trùng lắp
		if(exists (select * from GioHang where maKH=@maKH and maHD=@maHD and matrangthaiGioHang=@matrangthai))
		begin 
			print(N'Thông tin bị trùng lắp')
			rollback transaction
			return
		end
		--sửa
		Update GioHang set maHD=@maHD,matrangthaiGioHang=@matrangthai where maKH=@maKH
		SELECT * FROM GioHang WHERE maKH=@maKH
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
--Xóa
create proc xoa_giohang(@maKH nvarchar(10))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM GioHang WHERE maKH=@maKH
		if( @maKH is null)
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
		--Kiểm tra khách hàng đã có giỏ hàng
		if(not exists (select * from GioHang where maKH=@maKH))
		begin 
			print(N'Khách hàng không có giỏ hàng')
			rollback transaction
			return
		end
		--xóa
		delete from GioHang where maKH=@maKH
		SELECT * FROM GioHang WHERE maKH=@maKH
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--														HÓA ĐƠN
--Thêm
create proc them_hoadon (@maHD nvarchar(11), @maCN nvarchar(3), @nhanvienphutrachHD nvarchar(10), @maKH nvarchar(10), @tenKH nvarchar(10), @sdt nvarchar(12), @quan nvarchar(15), @phuong nvarchar (15), @diachiCT nvarchar(50), @thoigiangiaohang datetime, @maloaithanhtoan int, @ngaylapphieu date,  @magiamgia int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM HoaDon WHERE maChiNhanh=@maCN
		if(@maHD is null or @maCN is null or @nhanvienphutrachHD is null or @tenKH is null or @sdt is null or @quan is null or @phuong is null or @diachiCT is null or @thoigiangiaohang is null or @maloaithanhtoan is null or @ngaylapphieu is null)
		begin 
			print(N'Thông tin không được rỗng')
			rollback transaction
			return
		end
		--Kiểm tra mã hóa đơn có tồn tại
		if(exists (select * from HoaDon where maHD=@maHD))
		begin 
			print(N'Mã hóa đơn đã tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra mã chi nhánh có tồn tại
		if(not exists (select * from ChiNhanh where maChiNhanh=@maCN))
		begin 
			print(N'Mã chi nhánh không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra nhân viên phụ trách có tồn tại
		if(not exists (select * from NhanVien where manv=@nhanvienphutrachHD))
		begin 
			print(N'Mã nhân viên không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra loại thanh toán có tồn tại
		if(not exists (select * from LoaiThanhToan where maloaithanhtoan=@maloaithanhtoan))
		begin 
			print(N'Mã loại thanh toán không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra mã giảm giá (nếu khác null) có tồn tại
		if(@magiamgia is not null and not exists (select * from UuDaiThanhToan where maloaiuudai=@magiamgia and maloaithanhtoan=@maloaithanhtoan))
		begin 
			print(N'Mã giảm giá không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra địa chỉ giao hàng với chi nhánh
		declare @loaichiphigiaohang int
		if (exists (select * from ChiNhanh where maChiNhanh=@maCN and Quan=@quan and phuong=@phuong))
			set @loaichiphigiaohang = 1 --miễn phí giao hàng
		if (exists (select * from ChiNhanh where maChiNhanh=@maCN and Quan=@quan and not(phuong=@phuong)))
			set @loaichiphigiaohang = 2 --tính phí 20k
		if (exists (select * from ChiNhanh where maChiNhanh=@maCN and not (Quan=@quan) and not(phuong=@phuong)))
			set @loaichiphigiaohang = 3 --tính phí 50k
		--Thêm
		insert into HoaDon
		values (@maHD,@maCN,@nhanvienphutrachHD,@maKH,@tenKH,@sdt,@quan,@phuong,@diachiCT,@thoigiangiaohang,0,@loaichiphigiaohang,0,@maloaithanhtoan,0,0,@ngaylapphieu,@magiamgia)
		SELECT * FROM HoaDon WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	Commit transaction
go
--Sửa thông tin hóa đơn
create proc update_hoadon (@maHD nvarchar(11), @maCN nvarchar(3), @nhanvienphutrachHD nvarchar(10), @maKH nvarchar(10), @tenKH nvarchar(10), @sdt nvarchar(12), @quan nvarchar(15), @phuong nvarchar (15), @diachiCT nvarchar(50), @thoigiangiaohang datetime, @matrangthaihd int, @maloaithanhtoan int, @ngaylapphieu date,  @magiamgia int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM HOADON WHERE maChiNhanh=@maCN
		if(@maHD is null or @maCN is null or @nhanvienphutrachHD is null or @tenKH is null or @sdt is null or @quan is null or @phuong is null or @diachiCT is null or @thoigiangiaohang is null or @maloaithanhtoan is null or @ngaylapphieu is null)
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
		--Kiểm tra mã chi nhánh có tồn tại
		if(not exists (select * from ChiNhanh where maChiNhanh=@maCN))
		begin 
			print(N'Mã chi nhánh không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra nhân viên phụ trách có tồn tại
		if(not exists (select * from NhanVien where manv=@nhanvienphutrachHD))
		begin 
			print(N'Mã nhân viên không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra loại thanh toán có tồn tại
		if(not exists (select * from LoaiThanhToan where maloaithanhtoan=@maloaithanhtoan))
		begin 
			print(N'Mã loại thanh toán không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra mã giảm giá (nếu khác null) có tồn tại
		if(@magiamgia is not null and not exists (select * from UuDaiThanhToan where maloaiuudai=@magiamgia and maloaithanhtoan=@maloaithanhtoan))
		begin 
			print(N'Mã giảm giá không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra loại chi phí giao hàng
		declare @loaichiphigiaohang int
		if (exists (select * from ChiNhanh where maChiNhanh=@maCN and Quan=@quan and phuong=@phuong))
		begin
			set @loaichiphigiaohang = 1 --miễn phí giao hàng
		end
		if (exists (select * from ChiNhanh where maChiNhanh=@maCN and Quan=@quan and not(phuong=@phuong)))
		begin
			set @loaichiphigiaohang = 2 --tính phí 20k
		end
		if (exists (select * from ChiNhanh where maChiNhanh=@maCN and not (Quan=@quan) and not(phuong=@phuong)))
		begin
			set @loaichiphigiaohang = 3 --tính phí 50k
		end
		--Tính tổng hóa đơn
		declare @tongHD money, @diem int
		set @tongHD = (select tongHD from HoaDon where mahd=@maHD) - (select CPGH from HoaDon, ChiPhiGiaoHang where mahd=@maHD and maloaiCP=loaiChiPhiGiaoHang) + (select CPGH from ChiPhiGiaoHang where maloaiCP=@loaichiphigiaohang) 
		set @diem = @tongHD
		--Kiểm tra hóa đơn đã xử lý
		if (exists (select * from HoaDon where maHD=@maHD and matrangthaihd=0)) -- mã trạng thái = 0 <=> chưa xử lý
		begin
			--thêm
			update HOADON set maChiNhanh=@maCN, maKH=@maKH, maNQLHD=@nhanvienphutrachHD, tenKH=@tenKH, sodtlienlac=@sdt, quan=@quan,phuong=@phuong, diachichitiet=@diachiCT, thoigiangiaohang=@thoigiangiaohang, maloaithanhtoan=@maloaithanhtoan,ngaylaphd=@ngaylapphieu, magiamgia=@magiamgia, tonghd=@tongHD, diemhd=@diem where maHD=@maHD 
		end
		update HOADON set matrangthaihd=@matrangthaihd where maHD=@maHD 
		--cập nhật điểm cho khách hàng
		set @diem= (select diemHD from HoaDon where maHD=@maHD)
		if ( @matrangthaihd= 4)
			exec capnhat_KH @maKH, @diem
		SELECT * FROM HOADON WHERE maChiNhanh=@maCN
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--Cập nhật khi chi tiết hóa đơn thay đổi
ALTER proc update_tongHD (@maHD nvarchar(11), @tien money,@so int)
as
Begin transaction
	Begin try
		--Kiểm tra mã hóa đơn có tồn tại
		SELECT * FROM HOADON WHERE maHD=@maHD
		if(not exists (select * from HoaDon where maHD=@maHD))
		begin 
			print(N'Mã hóa đơn không tồn tại')
			rollback transaction
			return
		end
		--Kiểm tra hóa đơn đã xử lý
		if ( exists (select * from HoaDon where maHD=@maHD and matrangthaihd=0)) -- mã trạng thái = 0 <=> chưa xử lý
		begin
			print(N'Hóa đơn đã được xử lý không thể thay đổi')
			rollback transaction
			return
		end
		declare @tongHD money, @diem int, @soluongmon int
		set @tongHD = (select tongHD from HoaDon where mahd=@maHD) + @tien
		set @diem=@tongHD
		set @soluongmon = (select soluongmon from HoaDon where mahd=@maHD) + @so
		--cập nhật
		update HoaDon set tonghd=@tongHD, diemHD=@diem, soluongmon=@soluongmon where maHD=@maHD
		SELECT * FROM HOADON WHERE maHD=@maHD
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--Xóa
create proc xoa_hoadon(@maHD nvarchar(11))
as
Begin transaction
	Begin try
		--Kiểm tra mã hóa đơn có tồn tại
		SELECT * FROM HOADON WHERE maHD=@maHD
		if(not exists (select * from HoaDon where maHD=@maHD))
		begin 
			print(N'Mã hóa đơn không tồn tại')
			rollback transaction
			return
		end
		if (not exists (select * from HoaDon where maHD=@maHD and matrangthaihd=0 or matrangthaihd=1)) -- mã trạng thái = 0 <=> chưa xử lý ; mã trạng thái = 1 <=> hóa đơn đã tiếp nhận
		begin
			print(N'Hóa đơn đã được xử lý không thể thay đổi')
			rollback transaction
			return
		end
		--Kiểm tra hóa đơn không còn món ăn nào
		if(exists (select * from HoaDon where maHD=@maHD and soluongmon > 0))
		begin 
			print(N'Vui lòng hủy hết chi tiết hóa đơn trước khi xóa')
			rollback transaction
			return
		end
		--xóa
		delete from HoaDon where maHD=@maHD
		SELECT * FROM HOADON WHERE maHD=@maHD
	End try
	Begin catch
		rollback transaction
	End catch

Commit transaction
go
--											CHI TIẾT HÓA ĐƠN
--Thêm
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

--sửa số phần trong chi tiết hóa đơn
create proc update_chitietHD (@maHD nvarchar(11), @machitietHD nvarchar(11), @mamon nvarchar(10), @sophan int)
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM ChiTietMenu WHERE maHD=@maHD
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
		if(not exists (select * from ChiTietHD where maHD=@maHD and mamon=@mamon))
		begin 
			print(N'Món ăn đã có trong hóa đơn')
			rollback transaction
			return
		end
		--Kiểm tra số phần có thay đổi
		if(exists (select * from ChiTietHD where maHD=@maHD and mamon=@mamon and machitietHD=@machitietHD and sophan=@sophan))
		begin 
			print(N'Số phần không thay đổi')
			rollback transaction
			return
		end
			--Kiểm tra hóa đơn đã xử lý
		if (not exists (select * from HoaDon where maHD=@maHD and matrangthaihd=0)) -- mã trạng thái = 0 <=> chưa xử lý
		begin
			print(N'Hóa đơn đã được xử lý không thể thay đổi')
			rollback transaction
			return
		end
		--Tính tổng tiền
		declare @tongtien money
		set @tongtien = (select gia from Mon where mamon=@mamon)*@sophan
		declare @tien money
		set @tien= @tongtien - (select tonggia from ChiTietHD where maHD=@maHD and machitietHD=@machitietHD)
		--sửa
		update ChiTietHD set sophan=@sophan, tonggia=@tongtien where maHD=@maHD and mamon=@mamon and machitietHD=@machitietHD
		--Cập nhật hóa đơn
		exec update_tongHD @mahd, @tien,0
		SELECT * FROM ChiTietMenu WHERE maHD=@maHD
		End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
--	Xóa
create proc xoa_ChiTietHD(@maHD nvarchar(11), @machitietHD nvarchar(11))
as
Begin transaction
	Begin try
		--Kiểm tra thông tin không được rỗng
		SELECT * FROM ChiTietMenu WHERE maHD=@maHD
		if( @maHD is null or @machitietHD is null)
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
		--Kiểm tra chi tiết hóa đơn có tồn tại
		if(not exists (select * from ChiTietHD where maHD=@maHD and machitietHD=@machitietHD))
		begin 
			print(N'Chi tiết hóa đơn không tồn tại')
			rollback transaction
			return
		end
		--xóa
		delete from ChiTietHD where maHD=@maHD and machitietHD=@machitietHD
		--Cập nhật hóa đơn
		declare @tien money
		set @tien= - (select tonggia from ChiTietHD where maHD=@maHD and machitietHD=@machitietHD)
		exec update_tongHD @mahd, @tien,-1
		SELECT * FROM ChiTietMenu WHERE maHD=@maHD
	End try
	Begin catch
		rollback transaction
	End catch
	
Commit transaction
go
---
CREATE PROC CHITIETTUNGHOADON
AS
BEGIN
	SELECT * FROM HOADON join CHITIETHD on HOADON.MAHD=CHITIETHD.MAHD
END