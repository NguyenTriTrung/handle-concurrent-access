/*
Xử lý đồng thời về vấn đề dirty read
Mô tả tình huống:
+Gỉa sử có một giao tác T1 đang xóa một đơn vị dữ liệu thì có giao tác khác T2 lại update trên đơn vị dữ liệu đó
và giao tác T3 thì đọc trên đơn vị dữ liệu đó.
--> vấn đề xảy ra là giao tác T3 đọc được đơn vị dữ liệu mà lúc đó T1 thao tác nhưng đơn vị dữ 
mà T1 thao tác lại xảy ra deadlock với đơn vị dữ liệu mà T2 thực hiên dẫn đến vấn đề là việc đọc của
T3 là sai,thật chất đơn vị dữ liệu đó chưa đọc xóa nhưng T3 lại đọc ra là được xóa.
--> đây không phải là vấn đề về phantom vì phantom là đọc 2 lần sẽ thêm(mất) dữ liệu,
còn đây là đọc dữ liệu chưa commit xong.

*/
--T1
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
	WAITFOR DELAY N'00:00:05'
	delete from Mon where maMon=@mamon
	update LOAI SET TONGSOMON=TONGSOMON-1 WHERE MALOAI=@maloaibandau
	SELECT * FROM MON WHERE maMon=@mamon
	End try
	Begin catch
		rollback transaction
	End catch
	--xóa và cập nhật lại số lượng của loại

Commit transaction
go
exec Xoa_mon N'ANVAT006'
--T2
--T2
ALTER proc Update_Mon (@mamon nvarchar(10),@tenmon nvarchar(40),@maloai nvarchar(3),@gia money,@gioithieu nvarchar(200))
as
Begin transaction
	Begin try
		--kiểm tra thông tin không được rỗng
		SELECT * FROM MON WHERE maMon=@mamon
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
	WAITFOR DELAY N'00:00:10'
	update Mon set tenMon=@tenmon, maLoai=@maloai, Gia=@gia, GioiThieu=@gioithieu where MAMON=@mamon
	--nếu đổi mã loại thì phải update lại số lượng món trong loại
	SELECT * FROM MON WHERE maMon=@mamon
	End try
	Begin catch
		PRINT N'LỖI'
		rollback transaction
	End catch
	--update
Commit transaction
go
EXEC Update_Mon N'ANVAT006',N'BÁNH BAO',N01,12.0000,N'ĂN KHAI VỊ'

--T3
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
SELECT * FROM MON

---GIẢI QUYẾT VẤN ĐỀ
--- NÂNG LÊN MỨC CÔ LẬP THỨ 2,CÓ SL
