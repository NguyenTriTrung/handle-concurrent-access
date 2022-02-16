/*với proc Update_Mon ta gặp phải trường hợp lostupdate
-Với giao tác là update một món ăn thì việc :
+giao tác T1 đọc dữ liệu sau đó update dữ liệu,nhưng T2 lại không thấy việc update mới của T1 
dẫn tới việc nếu ta cho 1 dòng select vào sẽ thấy rõ kết quả của việc update
ở T1 và T2 cho ra 2 kết quả khác nhau,lúc này dữ liệu Update của T1 đã bị T2 đè
lên.
--> ta xử lý bằng cách khóa trên đơn vị đọc và giữu khóa đọc cho đến hết giao tác
việc này dẫn đến giải quyết được lostupdate nhưng không giải quyết đucợ deadlock sinh ra.
--> để holdlock và row lock ở vị trí đó để cho giao tác khác biết rằng đơn vị dữ
liệu đó đang được khóa và giữu đến hết giao tác.
Nếu có giao tác khác xin đọc thì được nhưng xin update thì sẽ gây ra lỗi.
*/
--T1
ALTER  proc Update_Mon (@mamon nvarchar(10),@tenmon nvarchar(40),@maloai nvarchar(3),@gia money,@gioithieu nvarchar(200))
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
	waitfor delay '00:00:05'
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
exec Update_Mon N'ANVAT001',N'BÁNH PIZZA',N'N002',2.000,N'ĂN KHAI VỊ'
select* from LOAI
--T2
exec Update_Mon N'ANVAT001',N'BÁNH BAO',N'N00',1.000,N'ĂN KHAI VỊ'
--GIẢI QUYẾT LOSTUPDATE
ALTER  proc Update_Mon (@mamon nvarchar(10),@tenmon nvarchar(40),@maloai nvarchar(3),@gia money,@gioithieu nvarchar(200))
as
Begin transaction
	Begin try
		--kiểm tra thông tin không được rỗng
		select * from Mon WITH (HOLDLOCK,ROWLOCK)where maMon=@mamon
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
	waitfor delay '00:00:05'
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