read.data <- function(file) {
file.parts <- unlist(strsplit(file, "_"))
	file.c <- paste(dirdat, file, sep = "/")
	if( ! file.exists(file.c)) {
		cat(file, "does not exists\n")
		stop()
	}
	dte <- file.parts[number.of.fields.before.date + 1]
	tim <- file.parts[number.of.fields.before.date + 2]

	# extract information from date found in file name
	y <- formatC(substr(dte, 1, 2), format = "d", width = 2, flag = "0")
	m <- formatC(substr(dte, 3, 4), format = "d", width = 2, flag = "0")
	d <- formatC(substr(dte, 5, 6), format = "d", width = 2, flag = "0")
	H <- formatC(substr(tim, 1, 2), format = "d", width = 2, flag = "0")
	M <- formatC(substr(tim, 3, 4), format = "d", width = 2, flag = "0")
	dte <- as.POSIXct(strptime(paste(y, m, d, H, M, sep = ""), format = "%y%m%d%H%M"))
	tim <- as.numeric(H) + as.numeric(M) / 60

	# Modified by Simon Bélanger on Aug 2016 to process COPS data obtained with uprofile 1.9.10 and after
	# These files end by URC.csv or URC.tsv"
	if (str_detect(file, "URC.")) {
	  print("COPS data acquisition using uProfile 1.9.10 or later")
	  num <- file.parts[number.of.fields.before.date]
	  potential.gps.file.without.ext <- paste(c("GPS", file.parts[number.of.fields.before.date + 1]), collapse = "_")
	  potential.gps.file <- list.files(dirdat, pattern = potential.gps.file.without.ext)
	  if(length(potential.gps.file) < 0.5) potential.gps.file <- "NO_GPS_FILE"
	} else {
	  num <- file.parts[number.of.fields.before.date + 3]
	  potential.gps.file.without.ext <- paste(c(file.parts[1:(number.of.fields.before.date + 2)], "gps"), collapse = "_")
	  potential.gps.file <- list.files(dirdat, pattern = potential.gps.file.without.ext)
	  if(length(potential.gps.file) < 0.5) potential.gps.file <- "NO_GPS_FILE"
	}
	# end

	# Added by Simon
	index_ext = length(unlist(strsplit(file.c, "[.]")))	# for station names with periods, ex. G604.5
	ext = unlist(strsplit(file.c, "[.]"))[index_ext]
	if (ext == "tsv" || ext =="txt") {
	  x = read.table(file = file.c, header = TRUE, as.is = TRUE, sep = "\t", check.names = FALSE)
	} else{ x = read.table(file = file.c, header = TRUE, as.is = TRUE, sep = ",", check.names = FALSE)}
	# END

  ns <- names(x)
  # added by simon to process 2011 data
  if (str_detect(ns[1], "]")) {
    ns <- sub("[", "", ns, fixed = TRUE)
    ns <- sub("]", "", ns, fixed = TRUE)
  }
  ns=sapply(ns, strsplit, " ", perl=T) # Modified by Simon on June 22 2015
  ns = sapply(ns, "[[", 1) # Modified by Simon on June 22 2015
	names(x) <- ns

  #########################

	if(instruments.others == "NA") {
	  instruments <- instruments.optics
	} else {
	  instruments <- c(instruments.optics, instruments.others)
	}

	ks <- NULL
	for(instr in instruments) {
    print(instr)
		k <- grep(paste("^", instr, sep = ""), ns, value = TRUE)
		dummy <- x[k]
		names(dummy) <- sub(paste("^", instr, sep = ""), "", names(dummy))
		names(dummy) <- sub(paste("^", ":", sep = ""), "", names(dummy))
		anc <- sapply(
			strsplit(names(dummy), NULL),
			function(dum) {
				!all(dum %in% as.character(0:9))
			}
		)
		waves <- as.numeric(names(dummy[!anc]))
		assign(instr, as.matrix(dummy[!anc]))
		assign(paste(instr, "anc", sep = "."), dummy[anc])
		assign(paste(instr, "waves", sep = "."), waves)
		ks <- append(ks, k)
	}
	k.others <- ns[! ns %in% ks]
	Others <- x[k.others]
	ret <- list()
	for(instr in instruments) {
		ret <- c(ret, list(get(instr)))
	}
	for(instr in instruments) {
		ret <- c(ret, list(get(paste(instr, "anc", sep = "."))))
	}
	for(instr in instruments) {
		ret <- c(ret, list(get(paste(instr, "waves", sep = "."))))
	}
	ret <- c(ret, list(Others))
	names(ret) <- c(instruments, paste(instruments, "anc", sep = "."), paste(instruments, "waves", sep = "."), "Others")
	ret <- c(ret, list(file = file, potential.gps.file = potential.gps.file))
	ret
}
