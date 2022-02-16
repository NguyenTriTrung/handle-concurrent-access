
/*
MÔ TẢ TÌNH HUỐNG:
-CÓ MỘT GIAO TÁC THỰC HIỆN VIỆC UDPATE SỐ LƯỢNG MÓN THUỘC LOẠI VÀ UPDATE MÓN,NHƯNG BỊ DELAY TRƯỚC KHI
UPDATE MÓN VÀ CÓ MỘT GIAO TÁC(T2) ĐỌC TABLE LOAI (MỨC CÔ LẬP SỐ 1) VÀ THẤY DỮ LIỆU LÚC NÀY CHƯA ĐƯỢC UPDATE MÓN NHƯNG RÕ RÀNG LÀ 
SỐ LƯỢNG LOẠI ĐÃ ĐƯỢC UPDATE .LỖI NÀY LÀ DIRTY READ.
GIẢI QUYẾT LÀ NÂNG MỨC CÔ LẬP LÊN SỐ 2
*/
--T1
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
	WAITFOR DELAY N'00:00:05'
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
EXEC Update_Mon ANVAT012,N'BÁNH MÌ QUE',N01,20.00,N'không có'

--T2
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
CREATE PROC CHITIETLOAI
AS
BEGIN
	SELECT * FROM LOAI join Mon on LOAI.MALOAI=Mon.MALOAI
END
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED
EXEC CHITIETLOAI

----GIẢI QUYẾT LÀ NÂNG MỨC CÔ LẬP LÊN SỐ 2