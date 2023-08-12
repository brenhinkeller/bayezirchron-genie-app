[
    heading("{{title}}", content="    using the method of Keller et al. (2018)")

    row([
      btn(class = "q-my-rt", "Refresh", @click("refresh+=1"), color = "primary"),
    ])

    row([
      cell(class="st-module", [
        uploader(label="Upload data", accpt=".csv", multiple=true, method="POST", url="http://localhost:8000/", field__name="csv_file"),
      ])
      cell(size=3, class="st-module", [
        h6("File")
        Stipple.select(:selected_file; options=:upfiles)
      ])
      cell(size=2, class="st-module", [
        h6("Input sigma level")
        Stipple.select(:input_sigma_level; options=:sigmas)
      ])
      cell(size=1, class="st-module", [
        h6("Delimiter")
        Stipple.select(:selected_delimiter; options=:delimiters)
      ])
    ])

    row([
      cell(class="st-module", [
        h5("Data")
        table(title="Data", :datatable; style="height: 350px;")
      ])
      cell(class="st-module", [
        h5("Rank-order plot")
        plot(:rankorder)
      ])
   ])

   row([
     cell(class="st-module", [
       h6("Number of steps")
       Stipple.select(:selected_steps; options=:steps)
       br()
       br()
       hr()
       h6("Burnin")
       Stipple.select(:selected_burnin; options=:burnins)
       br()
       br()
       hr()
       h6("Relative crystallization distribution")
       Stipple.select(:selected_dist; options=:distributions)
     ])

     cell(class="st-module", [
       h5("Selected relative crystallization distribution")
       plot(:distplot)
     ])
  ])

  row([
    btn(class = "q-my-rt", "Calculate", @click("calculate+=1"), color = "primary")
    h5("This may take a while, only click once")
  ])

  row([
    cell(class="st-module", [
      h5("Results")
      table(title="Results", :resultstable; style="height: 150px;")
      plot(:resultsplot)
    ])
  ])

  row([
    cell(class="st-module", [
      h5("Log likelihood")
      plot(:llplot)
    ])
    cell(class="st-module", [
      h5("Collected distribution")
      plot(:markovplot)
    ])
  ])


] |> string
