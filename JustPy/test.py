import justpy as jp
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


def button_click(self, msg):
    self.num_clicked += 1
    # self.message.text = f'{self.text} clicked. Number of clicks: {self.num_clicked}'
    p = jp.P(text=f'{self.text} clicked. Number of clicks: {self.num_clicked}')
    self.message.add_component(p, 0)
    for button in msg.page.button_list:
        button.set_class('bg-blue-500')
        button.set_class('bg-blue-700', 'hover')
    self.set_class('bg-red-500')
    self.set_class('bg-red-700', 'hover')

def event_demo():
    number_of_buttons = 25
    wp = jp.WebPage()
    button_div = jp.Div(classes='flex m-4 flex-wrap', a=wp)
    button_classes = 'w-32 mr-2 mb-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded-full'
    message = jp.Div(classes='text-lg border m-2 p-2 overflow-auto h-64', a=wp)
    message.add(jp.P(text='No button clicked yet'))
    button_list = []
    for i in range(1, number_of_buttons + 1):
        b = jp.Button(text=f'Button {i}', a=button_div, classes=button_classes, click=button_click)
        b.message = message
        b.num_clicked = 0
        button_list.append(b)
    wp.button_list = button_list   # The list will now be referenced by the WebPage instance attribute
    return wp

wm = pd.read_csv('https://elimintz.github.io/women_majors.csv').round(2)
# Create list of majors which start under 20% women students
wm_under_20 = list(wm.loc[0, wm.loc[0] < 20].index)

def women_majors():
    wp = jp.WebPage()
    wm.jp.plot(0, wm_under_20, kind='spline', a=wp, title='The gender gap is transitory - even for extreme cases',
               subtitle='Percentage of Bachelors conferred to women form 1970 to 2011 in the US for extreme cases where the percentage was less than 20% in 1970',
                classes='m-2 p-2 w-3/4')
    return wp

#jp.justpy(women_majors)

button_classes='m-2 bg-blue-500 hover:bg-blue-700 text-white font-bold py-2 px-4 rounded'
def toggle_show(self, msg):
    self.d.show = not self.d.show
    self.d2.text='New Text'
    self.d2.show = not self.d2.show

def show_demo():
    wp = jp.WebPage()
    b = jp.Button(text='Click to toggle show', a=wp, classes=button_classes)
    d = jp.Div(text='Toggled by show1', classes='m-2 p-2 text-2xl border w-48', a=wp)
    b.d = d
 
    d2 = jp.Div(text='Toggled by show2', classes='m-2 p-2 text-2xl border w-48', a=wp)
    b.d2 = d2
    d2.show = False



    b.on('click', toggle_show)

    b = jp.Button(text='Click to toggle visibility', a=wp, classes=button_classes)
    d = jp.Div(text='Toggled by visible', classes='m-2 p-2 text-2xl border w-48', a=wp)
    d.visibility_state = 'visible'
    b.d = d
    jp.Div(text='Will always show', classes='m-2', a=wp)

    def toggle_visible(self, msg):
        if self.d.visibility_state == 'visible':
            self.d.set_class('invisible')
            self.d.visibility_state = 'invisible'
        else:
            self.d.set_class('visible')
            self.d.visibility_state = 'visible'

    b.on('click', toggle_visible)
    return wp

#jp.justpy(show_demo)



alert_dialog_html = """
<div class="q-pa-md q-gutter-sm">
    <q-btn label="Alert" color="primary" name="alert_button" />
    <q-dialog name="alert_dialog" persistent>
      <q-card>
        <q-card-section>
          <div class="text-h6">Alert</div>
        </q-card-section>

        <q-card-section>
          Lorem ipsum dolor sit amet consectetur adipisicing elit. Rerum repellendus sit voluptate voluptas eveniet porro. Rerum blanditiis perferendis totam, ea at omnis vel numquam exercitationem aut, natus minima, porro labore.
        </q-card-section>

        <q-card-actions align="right">
          <q-btn flat label="OK" color="primary" v-close-popup />
        </q-card-actions>
      </q-card>
    </q-dialog>
</div>
"""

seamless_dialog_html = """
<div class="q-pa-md q-gutter-sm">
    <q-btn label="Open seamless Dialog" color="primary" name="seamless_button" />

    <q-dialog seamless position="bottom" name="seamless_dialog">
      <q-card style="width: 350px">
        <q-linear-progress :value="0.6" color="pink" />

        <q-card-section class="row items-center no-wrap">
          <div>
            <div class="text-weight-bold">The Walker</div>
            <div class="text-grey">Fitz & The Tantrums</div>
          </div>

          <q-space />

          <q-btn flat round icon="play_arrow" />
          <q-btn flat round icon="pause" />
          <q-btn flat round icon="close" v-close-popup />
        </q-card-section>
      </q-card>
    </q-dialog>
  </div>
"""


def open_dialog(self, msg):
    self.dialog.value = True

def dialog_test():
    wp = jp.QuasarPage()

    c = jp.parse_html(alert_dialog_html, a=wp)
    c.name_dict["alert_button"].dialog = c.name_dict["alert_dialog"]
    c.name_dict["alert_button"].on('click', open_dialog)

    c = jp.parse_html(seamless_dialog_html, a=wp)
    c.name_dict["seamless_button"].dialog = c.name_dict["seamless_dialog"]
    c.name_dict["seamless_button"].on('click', open_dialog)

    return wp

#jp.justpy(dialog_
def plot_test():
    wp = jp.WebPage()
    jp.Div(text='Multiple Pie Charts', a=wp, classes='text-white bg-blue-500 text-center text-xl')
    df_pie = pd.DataFrame(3 * np.random.rand(4, 1),index=['a', 'b', 'c', 'd'], columns=['x'])
    df_pie.plot.pie(subplots=True, figsize=(8, 4))
    jp.Matplotlib(a=wp)
    plt.close()
    return wp

jp.justpy(plot_test)