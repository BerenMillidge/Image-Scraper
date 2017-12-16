#Image scraper using Julia and Selenium. Current build only scrapes google image

using PyCall
using WebDriver
using Requests
using JSON
using ArgParse


function scrollThroughPage(driver::WebDriver.Driver)

	#Scrolls down to the bottom of each page of the image search, to reveal all images
	
	const scrollScript = "window.scrollBy(0, 1000000)"
	const waitTime= 0.2
	const scrolls = 5
	for i in 1:scrolls
		execute_script(driver, scrollScript)
		sleep(waitTime)
	end
end

function clickThroughPage(driver::WebDriver.Driver)
	
	#clicks through to the next page of the image search automatically

	const nextButtonSelector = "//input[@value='Show more results']"
	const waitTime= 0.2
	click(find_element_by_xpath(driver, nextButtonSelector))
	sleep(waitTime)
end


function parseImageElement(img::WebDriver.WebElement, extensions::Tuple)

	#gets the image url and type of the html image elements extracted from the page	
	
	innerhtml = JSON.parse(get_attribute(img, "innerHTML"))
	img_url = innerhtml["ou"]
	img_type = innerhtml["ity"]

	#we do our default type replacing here
	if !(img_type in extensions)
		img_type = "jpg"
	end
	return img_url, img_type
end

function requestAndSaveImage(url::AbstractString, fname::AbstractString, stream::Bool=false)

	#requests an image given a url and saves it or streams it to a file
		
	if stream == true
		try
			stream = Requests.get_streaming(url)
			open(fname, "w") do file
				while !eof(stream)
					write(file, readavailable(stream))
				end
			end
		catch Exception e
			println("Image stream failed: " * e)
		end
	end

	if stream ==false
		try
			res = Requests.get(url)
			Requests.save(res, fname)
		catch Exception e
			println("Image download failed: " *e)
		end
	end
end

function setupDirectories()
	if !isdir(basepath)
		mkdir(basepath)
	end
end

#the big function so we can see if anything works

function scrape_images_routine(searchTerm::AbstractString, num_images::Integer, basepath::AbstractString=searchTerm, streaming::Bool=false, parallel::Bool = false, extensions::Tuple=("jpg", "jpeg", "png", "gif"), verbose::Bool = true)

	#setup our constants
	const url = "https://www.google.co.in/search?q="*searchTerm*"&source=lnms&tbm=isch"
	const images_per_page = 400
	const number_of_scrolls = num_images/images_per_page +1

	const driver_path = "/home/beren/work/julia/misc/chromedriver" 
	driver = init_chrome(driver_path)
	#also should allow driver customizatoin at some point, but can't be bothered - could perhaps pare this into a separate function also for  ease
	if verbose==true
		println("Driver initialized")
	end
	#get the search term
	get(driver, url)
	if verbose==true
		println("Searching for " * searchTerm)
	end
	
	#if all of this works, we make the dirs for our thing
	setupDirectories()

	img_counter::Integer = 0
	for i in 1:number_of_scrolls
		scrollThroughPage(driver) # scroll through page to load all images
		images = find_elements_by_xpath(driver,"//div[contains(@class, 'rg_meta')]") # get image urls
		println("Total Images found on this page: " * string(length(images)))
		for img in images

			img_url, img_type = parseImageElement(img, extensions) # parse our image
			fname = basepath*searchTerm * "_"*string(img_counter)*"."*img_type # create filename for saving
			requestAndSaveImage(img_url, fname, streaming)
			img_counter +=1
			
			#and we check our loop functionality
			if img_counter >= num_images
				if verbose==true
					println(string(num_images) *" images found. Image scraper exiting")
				end
				return
			end
		end
	end
end


# okay, commandline functoins

function parseCommandLine()
	s = ArgParseSettings(prog="Julia Image Scraper with Selenium", description="An image scraper of google images written in Julia", commands_are_required=false, version="0.0.1", add_version=true)

	@add_arg_table s begin
		"search_term"
			help="the search you want to get images from"
			required=true
			arg_type = String
		"number_images"
			help="the number of images you want to scrape"
			required=true
			arg_type = Int
		"base_path"
			help="the base path of the directory you want to save the images in"
			arg_type=String
			default=""
		"-s"
			help="whether to stream images or download them and save all at once"
			action = :store_true
		"-p"
			help="whether to download images in parallel"
			action= :store_true
		"-v"
			help="run the scraper in verbose mode"
			action = :store_true
	end
	return parse_args(s)
end

function run_scrape_from_cmdline()
	args = parseCommandLine()
	const search_term = args["search_term"]
	const num = args["number_images"]
	const base_path = args["base_path"]
	const stream = args["-s"]
	const parallel = args["-p"]
	const verbose = args["-v"]
	scrape_images_routine(search_term, num, base_path, stream, parallel, verbose)
end


print(isinteractive())

#run the file from the commandline if it is active
if isinteractive()
	run_scrape_from_cmdline()
end


# and now for our functions allowing a greater specialisation of arguments

function scrape_images(searchTerm::AbstractString, num_images::Integer, basepath::AbstractString=searchTerm, streaming::Bool=false, parallel::Bool = false, extensions::Tuple=("jpg", "jpeg", "png", "gif"), verbose::Bool = true)
	
	#this is identical to the routine, we just call it
	scrape_images_routine(searchTerm, num_images, basepath, streaming, parallel, extensions, verbose)
end

function scrape_images(searchTerm::Array{AbstractString}, num_images::Integer, basepath::AbstractString="", streaming::Bool=false, parallel::Bool = false, extensions::Tuple=("jpg", "jpeg", "png", "gif"), verbose::Bool = true)

	const len = length(searchTerm)
	for i in 1:len
		scrape_images_routine(searchTerm[i], num_images, basepath, streaming, parallel, extensions, verbose)
	end
end

function scrape_images(searchTerm::Array{AbstractString}, num_images::Array{Integer}, basepath::AbstractString="", streaming::Bool=false, parallel::Bool = false, extensions::Tuple=("jpg", "jpeg", "png", "gif"), verbose::Bool = true)

	const len = length(searchTerm)
	@assert len == length(num_images) "number of terms and number of images for each term must be the same length"
	for i in 1:len
		scrape_images_routine(searchTerm[i], num_images[i], basepath, streaming, parallel, extensions, verbose)
	end
end

function scrape_images(searchTerm::Array{AbstractString}, num_images::Array{Integer}, basepath::Array{AbstractString}, streaming::Bool=false, parallel::Bool = false, extensions::Tuple=("jpg", "jpeg", "png", "gif"), verbose::Bool = true)

	const len = length(searchTerm)
	@assert len == length(num_images) == length(basepath) "number of terms and number of images for each term must be the same length as must the number of different basepaths for each"
	for i in 1:len
		scrape_images_routine(searchTerm[i], num_images[i], basepath[i], streaming, parallel, extensions, verbose)
	end
end

		
